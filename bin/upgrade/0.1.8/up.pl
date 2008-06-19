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
use lib "$Bin/../../../lib";
use Foorum::SUtils qw/schema/;
use Foorum::Utils qw/uuid_string/;

my $schema = schema();

# from Foorum v0.1.8 on,
# we add a new column 'uuid' for table 'scheduled_email'

my $dbh = $schema->storage->dbh;
$dbh->do(
    q~ALTER TABLE `scheduled_email` ADD `uuid` VARCHAR( 36 ) NOT NULL DEFAULT '0';~ )
    or die $dbh->errstr;
print
    "[OK]ALTER TABLE `scheduled_email` ADD `uuid` VARCHAR( 36 ) NOT NULL DEFAULT '0';\n";
$dbh->do( q~ALTER TABLE `scheduled_email` ADD INDEX ( `uuid` ) ;~ ) or die $dbh->errstr;
print "[OK]ALTER TABLE `scheduled_email` ADD INDEX ( `uuid` ) ;\n";

# populate data to scheduled_email
my $rs = $schema->resultset('ScheduledEmail')->search();
while ( my $r = $rs->next ) {
    my $uuid = uuid_string();
    $r->update( { uuid => $uuid } );
    print "Update " . $r->email_id . ' with ' . $uuid . "\n";
}

print "Done\n";

1;
