package Foorum::TheSchwartz::Worker::DailyReport;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema config theschwartz/;
use Foorum::Log qw/error_log/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $config = config();
    my $schema = schema();

    my $time = time() - 24 * 60 * 60;

    # check db
    my $new_added_ip = $schema->resultset('BannedIp')->count( { time => { '>', $time } } );
    my $new_added_user = $schema->resultset('User')->count( { register_time => { '>', $time } } );
    my $new_added_visits = $schema->resultset('Visit')->count( { time => { '>', $time } } );
    my $left_email = $schema->resultset('ScheduledEmail')->count( { processed => 'N' } );
    my $sent_email = $schema->resultset('ScheduledEmail')->count( {
        processed => 'Y',
        time => \"> DATE_SUB(NOW(), INTERVAL 1 DAY)",
    } );
    my $log_error_count = $schema->resultset('LogError')->count( {
        time => \"> DATE_SUB(NOW(), INTERVAL 1 DAY)",
    } );
    my $log_path_count = $schema->resultset('LogPath')->count( {
        time => \"> DATE_SUB(NOW(), INTERVAL 1 DAY)",
    } );
    
    my $text_body = qq~
        NewAddedIP:     $new_added_ip\n
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
            subject    => 'Daily Report @ ' . scalar(localtime()),
            plain_body => $text_body,
            time       => \'NOW()',
            processed  => 'N',
        }
    );
    my $client = theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');

    $job->completed();
}

1;