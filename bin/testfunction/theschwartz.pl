#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::XUtils qw/config/;
my $config = config();
use DBI;

print "Connect to "
    . $config->{theschwartz_dsn}
    . " with user: "
    . $config->{dsn_user} . "\n";

my $dbh
    = DBI->connect( $config->{theschwartz_dsn}, $config->{dsn_user}, $config->{dsn_pwd} )
    or die $DBI::errstr;

my $theschwartz = TheSchwartz->new(
    databases => [
        {   dsn  => $config->{theschwartz_dsn},
            user => $config->{dsn_user},
            pass => $config->{dsn_pwd},
        }
    ],
    verbose => 1,
);

$theschwartz->insert("Foorum::TheSchwartz::Worker::SendScheduledEmail");

1;
