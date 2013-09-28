#!/usr/bin/env perl
#===============================================================================
#
#         FILE: validate.pl
#
#        USAGE: ./validate.pl --server ns1.example.com
#
#  DESCRIPTION: validate nameserver against zonefile
#
#      OPTIONS: See POD
# REQUIREMENTS: Modern::Perl, Config::TinyDNS, File::Slurp, Net::DNS,
#               Getopt::Long, Pod::Usage, Progress::Any, Progress::Any::Output
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Peter Ezetta (pe), peter.ezetta@zonarsystems.net
#      COMPANY: Zonar Systems, Inc.
#      VERSION: 1.0
#      CREATED: 07/30/13 10:00:00
#     REVISION: ---
#===============================================================================

use Modern::Perl 2011;
use autodie;
use Config::TinyDNS qw(split_tdns_data);
use File::Slurp;
use Net::DNS;
use Getopt::Long;
use Pod::Usage;
use Progress::Any;
use Progress::Any::Output;
use Data::Printer;

#-------------------------------------------------------------------------------
#  parse options, display usage text if necessary
#-------------------------------------------------------------------------------
my $zonefile = 'data';
my $server;
my $verbose = 0;
my $help    = 0;
my $a;
my $mx;
my $txt;

GetOptions(
    'zone=s'   => \$zonefile,
    'server=s' => \$server,
    'verbose'  => \$verbose,
    'help'     => \$help,
    'a'        => \$a,
    'mx'       => \$mx,
    'txt'      => \$txt,
);

pod2usage(1) if $help or not $server;

#-------------------------------------------------------------------------------
#  read and parse zonefile
#-------------------------------------------------------------------------------
my $data = read_file($zonefile);
my @parsedata = split_tdns_data $data or die;

#-------------------------------------------------------------------------------
#  set up DNS resolver.
#-------------------------------------------------------------------------------
my $resolver = Net::DNS::Resolver->new(
    nameservers => [$server],
    recurse     => 0,
    debug       => 0
);

#-------------------------------------------------------------------------------
#  set up progress bar
#-------------------------------------------------------------------------------
my $progress = Progress::Any->get_indicator( task => 'validate' );

Progress::Any::Output->set('TermProgressBarColor');

#-------------------------------------------------------------------------------
#  global variables
#-------------------------------------------------------------------------------
my $packet;
my @report;
my $addr;
my @answer;
my @record;
my $success;
my @txtdata;

#-------------------------------------------------------------------------------
#  validate A records
#-------------------------------------------------------------------------------
if ($a) {
    $progress->pos(0);
    $progress->target( ~~ @parsedata );
    say "Validating 'A' records against file: $zonefile";

    foreach (@parsedata) {
        @record = @{$_};

        unless ( $record[0] eq '+' ) {
            $progress->update();
            next;
        }

        $packet = $resolver->query( $record[1], 'A' );

        # move on if we can't resolve
        unless ($packet) {
            say "Unable to resolve $record[1]";
            next;
        }

        @answer = $packet->answer;

        foreach (@answer) {
            $addr = $_->address;

            if ( $record[2] eq $addr ) {
                $success = 1;
                say "$record[1] Validated" if $verbose;
            }
        }

        unless ($success) {
            push @report,
              "$record[1] Failed, Expected: $record[2] Received: $addr";
        }
        $success = 0;
        $progress->update();
    }
    $progress->finish();
}

#-------------------------------------------------------------------------------
#  validate MX records
#-------------------------------------------------------------------------------
if ($mx) {

    $progress->pos(0);
    $progress->target( ~~ @parsedata );
    say "Validating 'MX' records against file: $zonefile";

    foreach (@parsedata) {
        @record = @{$_};

        unless ( $record[0] eq '@' ) {
            $progress->update();
            next;
        }

        $packet = $resolver->query( $record[1], 'MX' );

        # move on if we can't resolve
        unless ($packet) {
            say "Unable to resolve $record[1]";
            next;
        }

        @answer = $packet->answer;
        foreach (@answer) {
            $addr = $_->exchange;
            if ( $addr eq $record[3] ) {
                $success = 1;
                say "$record[1] Validated" if $verbose;
            }
        }
        unless ($success) {
            push @report,
              "$record[1] Failed, Expected: $record[3] Received: $addr";
        }
        $success = 0;
        $progress->update();
    }
    $progress->finish();
}

if ($txt) {
    $progress->pos(0);
    $progress->target( ~~ @parsedata );
    say "Validating 'TXT' records against file: $zonefile";

    foreach (@parsedata) {
        @record = @{$_};

        unless ( $record[0] eq "'" ) {
            $progress->update();
            next;
        }
        $packet = $resolver->query( $record[1], 'TXT' );

        # move on if we can't resolve
        unless ($packet) {
            say "Unable to resolve $record[1]";
            next;
        }

        @answer = $packet->answer;
        foreach (@answer) {
            @txtdata = $_->txtdata;
            if ( grep( /$record[2]/, @txtdata ) ) {
                $success = 1;
                say "$record[1] Validated" if $verbose;
            }
        }
        unless ($success) {
            push @report,
              "$record[1] failed, Expected: $record[2] Received: @txtdata";
        }
        $success = 0;
        $progress->update();
    }
    $progress->finish();
}

say "Validation Complete" unless @report;
foreach (@report) {
    say;
}

__END__

=head1 NAME

validate.pl - Validate remote name server against zone file.

=head1 SYNOPSIS

perl B<validate.pl> --server ns1.example.com

=head1 OPTIONS

=over 8

=item B<-h --help> 

Display a short help message and exit.

=item B<-s --server> I<ns1.example.com>

Remote DNS server to query.

=item B<-z --zone> I</path/to/zonefile> 

Path to zone file for validation.

=item B<-a>

Validate 'A' records

=item B<-m  --mx>

Validate 'MX' records

=item B<-t  --txt>

Validate 'TXT' records 

=item B<-v  --verbose> 

Increase output verbosity.

=back

=head1 DESCRIPTION

B<validate.pl> is a utility to parse TinyDNS zone files and a remote DNS 
server, and return any discrepancies that are discovered. By default,
B<validate.pl> will look in it's current working directory for a TinyDNS
zone file called I<data>.  This file will then be parsed, and A record
lookups will be performed against the nameserver provided to B<validate.pl>.
Setting the I<verbose> flag will cause B<validate.pl> to display every
hostname it checks, regardless of whether it passes validation or not.

=head1 TODO

=over 8

=item Add BIND support

=item Add support for all DNS record types

=item Write tests

=back

=cut
