dnsvalidator
============

NAME
       validate.pl - Validate remote name server against zone file.

SYNOPSIS
       perl validate.pl --server ns1.example.com

OPTIONS
       -h --help
               Display a short help message and exit.

       -s --server ns1.example.com
               Remote DNS server to query.

       -z --zone /path/to/zonefile
               Path to zone file for validation.

       -a      Validate 'A' records

       -m  --mx
               Validate 'MX' records

       -t  --txt
               Validate 'TXT' records

       -v  --verbose
               Increase output verbosity.

DESCRIPTION
       validate.pl is a utility to parse TinyDNS zone files and a remote DNS
       server, and return any discrepancies that are discovered. By default,
       validate.pl will look in it's current working directory for a TinyDNS
       zone file called data.  This file will then be parsed, and A record
       lookups will be performed against the nameserver provided to
       validate.pl.  Setting the verbose flag will cause validate.pl to
       display every hostname it checks, regardless of whether it passes
       validation or not.

TODO
       Add BIND support
       Add support for all DNS record types
       Write tests
