package Foorum::TheSchwartz::Worker::DailyReport;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/config/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my @args = $job->arg;

    my $config = config();
    my $schema = schema();

    my $time = time() - 86400;

    # check db
    my $new_added_user
        = $schema->resultset('User')->count( { register_time => { '>', $time } } );
    my $new_added_visits
        = $schema->resultset('Visit')->count( { time => { '>', $time } } );
    my $left_email = $schema->resultset('ScheduledEmail')->count( { processed => 'N' } );
    my $sent_email = $schema->resultset('ScheduledEmail')->count(
        {   processed => 'Y',
            time      => { '>', $time },
        }
    );
    my $log_error_count
        = $schema->resultset('LogError')->count( { time => { '>', $time }, } );
    my $log_path_count
        = $schema->resultset('LogPath')->count( { time => { '>', $time }, } );

    my $text_body = qq~
        NewAddedUser:   $new_added_user\n
        NewAddedVisit:  $new_added_visits\n
        ScheduledEmail: $left_email\n
        SentEmail:      $sent_email\n
        LogErrorCount:  $log_error_count\n
        LogPathCount:   $log_path_count\n
    ~;

    $schema->resultset('ScheduledEmail')->create(
        {   email_type => 'daily_report',
            from_email => $config->{mail}->{from_email},
            to_email   => $config->{mail}->{daily_report_email},
            subject    => '[Foorum] Daily Report @ ' . scalar( localtime() ),
            plain_body => $text_body,
            time       => time(),
            processed  => 'N',
        }
    );

    $job->completed();
}

1;
