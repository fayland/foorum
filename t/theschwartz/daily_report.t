#!/usr/bin/perl

use strict;
use warnings;
use t::theschwartz::TestTheSchwartz;
use MooseX::TheSchwartz;
use Foorum::TheSchwartz::Worker::DailyReport;

plan tests => 1;

run_test {
    my $dbh = shift;
    my $client = MooseX::TheSchwartz->new();
    $client->databases([$dbh]);

    {
        my $handle = $client->insert("Foorum::TheSchwartz::Worker::DailyReport");
        isa_ok $handle, 'MooseX::TheSchwartz::JobHandle', "inserted job";

        $client->can_do("Foorum::TheSchwartz::Worker::DailyReport");
        $client->work_until_done;

        # test if OK
        
    }
};
