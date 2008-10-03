#!/usr/bin/perl

use strict;
use warnings;

# for both Linux/Win32
my $has_proc_pid_file
    = eval "use Proc::PID::File; 1;";    ## no critic (ProhibitStringyEval)
my $has_home_dir
    = eval "use File::HomeDir; 1;";      ## no critic (ProhibitStringyEval)
if ( $has_proc_pid_file and $has_home_dir ) {

    # If already running, then exit
    if ( Proc::PID::File->running( { dir => File::HomeDir->my_home } ) ) {
        exit(0);
    }
}

use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', '..', 'lib' );
use Foorum::SUtils qw/schema/;

my $schema = schema();
my $dbh    = $schema->storage->dbh;

# from Foorum v0.2.8 on,

my $sql
    = q~ ALTER TABLE `forum_settings` CHANGE `value` `value` VARCHAR( 255 ) NOT NULL~;
$dbh->do($sql) or die $DBI::errstr;

print "Done\n";

1;
