#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/config/;
use MooseX::TheSchwartz;
use DBI;

my $config = config();

print "Connect to "
    . $config->{theschwartz_dsn}
    . " with user: "
    . $config->{dsn_user} . "\n";

my $dbh
    = DBI->connect( $config->{theschwartz_dsn}, $config->{dsn_user}, $config->{dsn_pwd} )
    or die $DBI::errstr;

my $theschwartz = MooseX::TheSchwartz->new(
    databases => [$dbh],
    verbose   => 1,
);

$theschwartz->insert("Foorum::TheSchwartz::Worker::SendScheduledEmail");

1;
