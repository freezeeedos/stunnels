#!/usr/bin/perl

use warnings;
use strict;

my $remote_ssh_port;
my $remote_ssh_host;
my $remote_user;
my $remote_port_range;
my $local_ports;
my $first_port;
my $last_port;
my $cmd;
my $hasfailed = 0;
my $ret = 0;
my $killmode = 0;
my $i = 0;
my @localports;
my @failed;


open(my $cfg, "<", "stunnels.cfg")
    or die qq{can't open config file: $!};
my @cfg = <$cfg>;

foreach(@ARGV)
{
    if(($_ eq qq{-k}) or ($_ eq qq{--kill}))
    {
#         print qq{Kill mode.\n};
        $killmode = 1;
#         exit 0;
    }
}

foreach(@cfg)
{
    if($_ =~ /^REMOTE_SSH_PORT=\d+/)
    {
        ($remote_ssh_port) = $_ =~ /^REMOTE_SSH_PORT=(\d+)/;
    }
    
    
    if($_ =~ /^REMOTE_SSH_HOST=\w+/)
    {
        ($remote_ssh_host) = $_ =~ /^REMOTE_SSH_HOST=([\w+\.\-*]*)/;
        print qq{Remote ssh host: $remote_ssh_host\n};
    }
    
    
    if($_ =~ /^REMOTE_PORT_RANGE=\d+\/\d+/)
    {
        ($remote_port_range) = $_ =~ /^REMOTE_PORT_RANGE=(\d+\/\d+)/;
    }
    
    if($_ =~ /^LOCAL_PORTS=.*/)
    {
        ($local_ports) = $_ =~ /^LOCAL_PORTS=(.*)/;
        @localports = split( ' ', $local_ports);
    }
    
    if($_ =~ /^REMOTE_USER=\w+/)
    {
        ($remote_user) = $_ =~ /^REMOTE_USER=(\w+)/;
    }
}

if($remote_ssh_port !~ /\d+/)
{
    print qq{Please specify a valid port number\n};
    exit -1;
}
if($remote_ssh_host !~ /[\w+\.\-*]*/)
{
    print qq{Please specify a valid hostname\n};
    exit -1;
}
if($remote_port_range !~ /\d+\/\d+/)
{
    print qq{Please specify a valid port range\n};
    exit -1;
}
($first_port) = $remote_port_range =~ /(\d+)\/\d+/;
($last_port) = $remote_port_range =~ /\d+\/(\d+)/;
foreach(@localports)
{
    if($_ !~ /\d+/)
    {
        print qq{Please specify valid local ports};
        exit -1;
    }
    for($i = $first_port;$i<$last_port+1;$i++)
    {
        $cmd = qq{ssh -q -o ExitOnForwardFailure=yes -f -N -R $i:localhost:$_ $remote_user\@$remote_ssh_host -p $remote_ssh_port};
        
        if($killmode == 1)
        {
            my $running = `ps ax`;
            my @running = split(qq{\n}, $running);
            foreach(@running)
            {
                if(grep(! /^.*grep.*$/, $_) && grep( /^.*$cmd.*$/, $_))
                {
#                     print qq{$_\n};
                    my ($pid) = $_ =~ /^\s*(\d+)/;
                    if(defined $pid)
                    {
#                         my $killret = 0;
                        my $killret = system(qq{kill -9 $pid});
                        if($killret != 0)
                        {
                            print qq{failed to kill process $pid: $?\n}
                        }
                        else
                        {
                            last;
                        }
                    }
                }
            }
        }
        else
        {
            $ret = system($cmd);
            if($ret == 0)
            {
                print qq{Successfully forwarded localhost:$_ to $remote_ssh_host:$i\n};
                last;
            }
        }
    }
    if($ret != 0)
    {
        $hasfailed = 1;
        push @failed, $_;
    }
}

if($hasfailed == 1)
{
    print qq{failed to forward the following ports:\n};
    foreach(@failed)
    {
        print qq{$_\n};
    }
}

