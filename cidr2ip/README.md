Convert CIDR(s) to a list of IP addresses

./cidr2ip.ps1 -cidr 192.168.0.0/27
./cidrWrapperScript.ps1 -sourceFile ./AS24560.txt

Background:

We had a sudden increase in DNS queries from a wireless provider in India.
This traffic may or may not have been at least somewhat legitimate.
So I first needed to search Splunk to see if we had legitimate traffic from 
their ASN. Which contains 3.5 million addresses o_O

Due to limitations in how I am logging the particular traffic I am looking for, 
I couldn't use the CIDRs to search Splunk directly (at least within my Splunk
skills).

But I can export a query from Splunk as a .csv and then use another PS script 
that will compare that .csv to a list of all the IP addresses to determine if 
we have traffic from them.  