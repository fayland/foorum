#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use Cwd qw/abs_path/;
use YAML qw/DumpFile LoadFile/;
use DBI;
use lib "$FindBin::Bin/../lib";

my $path = abs_path("$FindBin::RealBin/..");

print "You are going to configure Foorum for your own using.\n",
      "=" x 50,
      "\nPlease report bugs to AUTHORS if u meet any problem.\n\n";

print "We are saving your configure to\n", "$path/foorum_local.yml\n",
      "You can change it use a plain editor later\n\n";

DBI:
print "Your MySQL host (localhost by default): ";
my $dns_host = <>;chomp($dns_host);
$dns_host = 'localhost' unless ($dns_host);

print "Your MySQL user (root by default): ";
my $dns_user = <>;chomp($dns_user);
$dns_user = 'root' unless ($dns_user);

DBIPASS:
print "Your MySQL pass (required): ";
my $dns_password;
while ($dns_password = <>) {
    chomp($dns_password);
    if ($dns_password) {
        last;
    } else {
        goto DBIPASS;
    }
}

eval {
    DBI->connect("DBI:mysql:foorum:$dns_host", $dns_user, $dns_password, { RaiseError => 1, PrintError => 1 }) or die $DBI::errstr;
};
if ($@) {
    print "\nError:\n", $@, "\nPlease try it again\n\n";
    goto DBI;
}

my $yaml;
if (-e "$path/foorum_local.yml") {
    $yaml = LoadFile("$path/foorum_local.yml");
}

$yaml->{dsn} = 'DBI:mysql:foorum';
$yaml->{dsn_user} = $dns_user;
$yaml->{dsn_pwd}  = $dns_password;

print "\n\nSaving ....\n";
DumpFile("$path/foorum_local.yml", $yaml);

print "=" x 50, "\nDone!\n", "Thanks For Join US!\n";

