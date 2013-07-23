stunnels
========

Perl script to forward local ports to a range of remote ports.
When a service is successfully forwarded, the script will proceed to forward the next local port on the list.

Sample Output:

    quentin@kboum:~> ./stunnels.pl 
    Successfully forwarded localhost:22 to obiwan:50001
    Successfully forwarded localhost:5900 to obiwan:50002
    Successfully forwarded localhost:80 to obiwan:50003

