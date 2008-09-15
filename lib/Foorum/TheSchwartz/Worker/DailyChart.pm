package Foorum::TheSchwartz::Worker::DailyChart;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base qw( MooseX::TheSchwartz::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/tt2/;
use File::Spec;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();

    register_stat( $schema, 'User' );
    register_stat( $schema, 'Comment' );
    register_stat( $schema, 'Forum' );
    register_stat( $schema, 'Topic' );
    register_stat( $schema, 'Message' );
    register_stat( $schema, 'Visit' );

    my $tt2 = tt2();

    my @atime = localtime();
    my $year  = $atime[5] + 1900;
    my $month = $atime[4] + 1;
    my $day   = $atime[3];

    my @stats = $schema->resultset('Stat')
        ->search( { date => \"> DATE_SUB(NOW(), INTERVAL 7 DAY)", } )->all;

    my $stats;
    foreach (@stats) {
        my $date = $_->date;
        $date =~ s/\-//isg;
        $stats->{ $_->stat_key }->{$date} = $_->stat_value;
    }

    my $var = {
        title => "$month/$day/$year Chart",
        stats => $stats,
    };

    my $filename = sprintf( "%04d%02d%02d", $year, $month, $day );
    use File::Spec;
    my ( undef, $path ) = File::Spec->splitpath(__FILE__);
    use Cwd qw/abs_path/;
    $path = abs_path($path);

    $tt2->process(
        'site/stats/chart.html',
        $var,
        File::Spec->catfile(
            $path, '..',   '..',     '..',
            '..',  'root', 'static', 'stats',
            "$filename.html"
        )
    );

    $job->completed();
}

sub register_stat {
    my ( $schema, $table ) = @_;

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
    $sth->execute( $stat_key, $stat_value );

}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::DailyChart - Build daily chart

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

Daily chart is helpful to take care about the site.

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
