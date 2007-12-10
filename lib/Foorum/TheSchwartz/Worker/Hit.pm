package Foorum::TheSchwartz::Worker::Hit;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Data::Dump qw/dump/;
use Foorum::ExternalUtils qw/schema/;
use Foorum::Log qw/error_log/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $schema = schema();

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();

    my @update_cols;
    if ($hour == 1 and $min < 5) { # the first hour of today
        push @update_cols, ( hit_yesterday => \'hit_today', hit_today => \'hit_new' );
    } else {
        push @update_cols, ( hit_today => \'hit_today + hit_new' ); #'
    }
    if ($wday == 1 and ($hour == 1 and $min < 5)) { # Monday
        push @update_cols, ( hit_weekly => \'hit_new' ); #'
    } else {
        push @update_cols, ( hit_weekly => \'hit_weekly + hit_new' ); #'
    }
    if ($mday == 1 and ($hour == 1 and $min < 5)) { # The first day of the month
        push @update_cols, ( hit_monthly => \'hit_new' ); #'
    } else {
        push @update_cols, ( hit_monthly => \'hit_monthly + hit_new' ); #'
    }
        
    $schema->resultset('Hit')->search()->update( {
        @update_cols,
    } );
    $schema->resultset('Hit')->search()->update( {
        hit_new => 0
    } );
    
    error_log($schema, 'info', 'update_hit - '  . dump(\@update_cols) . ' @ ' . localtime());
    
    $job->completed();
}

1;