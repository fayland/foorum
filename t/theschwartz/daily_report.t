#!/usr/bin/perl

use strict;
use warnings;
use t::theschwartz::TestTheSchwartz;
use MooseX::TheSchwartz;
use Foorum::TheSchwartz::Worker::DailyReport;
use Foorum::TestUtils qw/schema rollback_db/;

plan tests => 2;

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
        my $schema = schema();
        my $mail_count = $schema->resultset('ScheduledEmail')->count( {
            template => 'daily_report',
        } );
        is($mail_count, 1, 'has 1 daily_report mail');
    }
};

END {

    # Keep Database the same from original
    rollback_db();
}

1;