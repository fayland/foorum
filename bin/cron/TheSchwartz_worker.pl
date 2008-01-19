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
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/theschwartz config/;
use Foorum::TheSchwartz::Worker::Hit;
use Foorum::TheSchwartz::Worker::RemoveOldDataFromDB;
use Foorum::TheSchwartz::Worker::ResizeProfilePhoto;
use Foorum::TheSchwartz::Worker::SendScheduledEmail;
use Foorum::TheSchwartz::Worker::DailyReport;
use Foorum::TheSchwartz::Worker::DailyChart;
use Foorum::TheSchwartz::Worker::SendStarredNofication;
use vars qw/$config/;

BEGIN {
    $config = config();
    if ( $config->{function_on}->{topic_pdf} ) {
        my $module = 'Foorum::TheSchwartz::Worker::Topic_ViewAsPDF';
        eval "use $module;";    ## no critic (ProhibitStringyEval)
        if ($@) {
            die "can't load $module with error: $@\n",
                "Or else, please set function_on: topic_pdf: 0 if u don't want this.\n";
        }
    }
}

my $client = theschwartz();

my $verbose = sub {
    my $msg = shift;
    $msg =~ s/\s+$//;
    if ( $msg eq 'TheSchwartz::work_once found no jobs' ) {

        # do nothing
    } elsif ( $msg eq 'job completed' ) {

        # add localtime()
        print STDERR 'job completed @ ' . localtime() . "\n";
    } else {
        print STDERR "$msg\n";
    }
};
$client->set_verbose($verbose);

$client->can_do('Foorum::TheSchwartz::Worker::Hit');
$client->can_do('Foorum::TheSchwartz::Worker::RemoveOldDataFromDB');
$client->can_do('Foorum::TheSchwartz::Worker::ResizeProfilePhoto');
$client->can_do('Foorum::TheSchwartz::Worker::SendScheduledEmail');
$client->can_do('Foorum::TheSchwartz::Worker::DailyReport');
$client->can_do('Foorum::TheSchwartz::Worker::DailyChart');
$client->can_do('Foorum::TheSchwartz::Worker::SendStarredNofication');
if ( $config->{function_on}->{topic_pdf} ) {
    $client->can_do('Foorum::TheSchwartz::Worker::Topic_ViewAsPDF');
}
$client->work();

1;
