package Foorum::TheSchwartz::Worker::RemoveOldDataFromDB;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema/;
use Foorum::Log qw/error_log/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $schema = schema();

    # for table 'visit'
    # 2592000 = 30 * 24 * 60 * 60
    my $old_time = $cron_config->{remove_db_old_data}->{visit} || 2592000;
    my $visit_status = $schema->resultset('Visit')->search( {
        time => { '<', time() - $old_time }
    } )->delete;
    
    # for table 'log_path'
    my $days_ago = $cron_config->{remove_db_old_data}->{log_path} || 30;
    my $log_path_status = $schema->resultset('LogPath')->search( {
        time => \"< DATE_SUB(NOW(), INTERVAL $days_ago DAY)",
    } )->delete;
    
    # for table 'log_error'
    $days_ago = $cron_config->{remove_db_old_data}->{log_error} || 30;
    my $log_error_status = $schema->resultset('LogError')->search( {
        time => \"< DATE_SUB(NOW(), INTERVAL $days_ago DAY)",
    } )->delete;
    
    # for table 'banned_ip'
    $days_ago = $cron_config->{remove_db_old_data}->{banned_ip} || 604800;
    my $banned_ip_status = $schema->resultset('BannedIp')->search( {
        time => { '<' , time() - $days_ago },
    } )->delete;
    
    # for table 'session'
    # 2592000 = 30 * 24 * 60 * 60
    my $session_status = $schema->resultset('Session')->search( {
        expires => { '<', time() },
    } )->delete;

    error_log($schema, 'info', <<LOG);
remove_db_old_data - status:
    visit - $visit_status
    log_path - $log_path_status
    log_error - $log_error_status
    banned_ip - $banned_ip_status
    session   - $session_status
LOG

    $job->completed();
}

1;