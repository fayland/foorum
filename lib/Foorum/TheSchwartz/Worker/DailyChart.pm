package Foorum::TheSchwartz::Worker::DailyChart;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema tt2/;
use Foorum::Log qw/error_log/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $schema = schema();

    register_stat($schema, 'User');
    register_stat($schema, 'Comment');
    register_stat($schema, 'Forum');
    register_stat($schema, 'Topic');
    register_stat($schema, 'Message');
    
    my $tt2 = tt2();
    
    my @atime = localtime();
    my $year = $atime[5] + 1900; my $month = $atime[4] + 1; my $day = $atime[3];
    
    my @stats =$schema->resultset('Stat')->search( {
        date => \"> DATE_SUB(NOW(), INTERVAL 7 DAY)",
    } )->all;
    
    my $stats;
    foreach (@stats) {
        my $date = $_->date;
        $date =~ s/\-//isg;
        $stats->{$_->stat_key}->{$date} = $_->stat_value;
    }
    
    my $var = {
        title => "$month/$day/$year Chart",
        stats => $stats,
    };
    
    my $filename = sprintf("%04d%02d%02d", $year, $month, $day);
    use File::Spec;
    my (undef, $path) = File::Spec->splitpath(__FILE__);
    
    $tt2->process('stats/chart.html', $var, "$path/../../../../root/stats/$filename.html");

    $job->completed();
}

sub register_stat {
    my ($schema, $table) = @_;
    
    my $stat_value = $schema->resultset($table)->count();
    
    my $stat_key = lc($table) . '_counts';
    
    my $dbh = $schema->storage->dbh;
    
    my $sql = q~SELECT COUNT(*) FROM stat WHERE stat_key = ? AND date = NOW()~;
    my $sth = $dbh->prepare($sql);
    $sth->execute($stat_key);
    
    my ($count) = $sth->fetchrow_array;
    
    unless ($count) {
        $sql = q~INSERT INTO stat SET stat_key = ?, stat_value = ?, date = NOW()~;
    } else {
        $sql = q~UPDATE stat SET stat_key = ?, date = NOW() WHERE stat_value = ?~;
    }
    $sth = $dbh->prepare($sql);
    $sth->execute($stat_key, $stat_value);
    
}

1;