#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/config/;
use Data::Dumper;
my $config = config();

print "Connect to " . $config->{theschwartz_dsn} . "with user: " . $config->{dsn_user} . "\n";

my $theschwartz =  TheSchwartz->new(
        databases => [ {
            dsn  => $config->{theschwartz_dsn},
            user => $config->{dsn_user},
            pass => $config->{dsn_pwd},
        } ],
        verbose => 1,
    );

$client->insert("Foorum::TheSchwartz::Worker::SendScheduledEmail");

1;