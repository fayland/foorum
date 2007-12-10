#!/usr/bin/perl

use strict;
use warnings;

# for both Linux/Win32
my $has_proc_pid_file = eval "use Proc::PID::File; 1;";
if ($has_proc_pid_file) {
    # If already running, then exit
    if (Proc::PID::File->running()) {
        exit(0);
    }
}

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/theschwartz/;

my $client = theschwartz();

use Getopt::Long;
my $debug = 1;
my $daemon = 0;
my $worker;

GetOptions("debug=i"  => \$debug,    # debug
           "daemon=i" => \$daemon,   # daemon
           "worker=s" => \$worker);  # manually inser a $worker

if ($worker) {
    run_worker($worker);
} elsif ($daemon) {

    use Schedule::Cron;
    my $cron =  new Schedule::Cron(sub { return 1; });
    $cron->add_entry("*/5 * * * *", \&run_worker('Hit')); # run every 5 minutes
    $cron->add_entry("10 3 * * *",  \&run_worker('RemoveOldDataFromDB')); # run everyday
    $cron->add_entry("0 0 * * *",   \&run_worker('DailyReport'));
    $cron->add_entry("0 0 * * *",   \&run_worker('DailyChart'));
    $cron->run();
} else {
    print <<USAGE;
    Usage: perl $0 --debug 1 --daemon 1
           perl $0 --debug 1 --worker DailyReport
USAGE
}

sub run_worker {
    my ($worker) = @_;
    debug($worker);
    $client->insert("Foorum::TheSchwartz::Worker::$worker");
}

sub debug {
    my ($msg) = @_;
    
    print "$msg \@" . localtime() . "\n" if ($debug);
}

1;