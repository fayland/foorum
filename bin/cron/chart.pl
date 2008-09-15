#!/usr/bin/perl

use strict;
use warnings;

# for both Linux/Win32
my $has_proc_pid_file = eval "use Proc::PID::File; 1;"; ## no critic (ProhibitStringyEval)
my $has_home_dir      = eval "use File::HomeDir; 1;";   ## no critic (ProhibitStringyEval)
if ( $has_proc_pid_file and $has_home_dir ) {

    # If already running, then exit
    if ( Proc::PID::File->running( { dir => File::HomeDir->my_home } ) ) {
        exit(0);
    }
}

use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/tt2/;
use Foorum::SUtils qw/schema/;
use Date::Calc qw/Add_Delta_Days/;

my $tt2    = tt2();
my $schema = schema();

my @atime = localtime();
my $year  = $atime[5] + 1900;
my $month = $atime[4] + 1;
my $day   = $atime[3];

( $year, $month, $day ) = Add_Delta_Days( $year, $month, $day, -7 );
my $date = sprintf( "%04d%02d%02d", $year, $month, $day );

my @stats = $schema->resultset('Stat')->search( { date => \"> $date", } )->all;

my $stats;
foreach (@stats) {
    $stats->{ $_->stat_key }->{ $_->date } = $_->stat_value;
}

my $var = {
    title => "$month/$day/$year Chart",
    stats => $stats,
};

my $filename = sprintf( "%04d%02d%02d", $year, $month, $day );

$tt2->process( 'site/stats/chart.html', $var,
    File::Spec->catfile( $Bin, '..', '..', 'root', 'static', 'stats', "$filename.html" )
);

1;
