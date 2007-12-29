#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use Cwd qw/abs_path/;
use YAML qw/DumpFile LoadFile/;
use DBI;
use lib "$FindBin::Bin/../lib";
use vars qw/$dbh/;

my $path = abs_path("$FindBin::RealBin/..");

print "You are going to configure Foorum for your own using.\n",
    "=" x 50,
    "\nPlease report bugs to AUTHORS if u meet any problem.\n\n";

print "We are saving your configure to\n", "$path/foorum_local.yml\n",
    "You can change it use a plain editor later\n\n";

DBI:
print "Your MySQL host (localhost by default): ";
my $dns_host = <>;
chomp($dns_host);
$dns_host = 'localhost' unless ($dns_host);

print "Your MySQL user (root by default): ";
my $dns_user = <>;
chomp($dns_user);
$dns_user = 'root' unless ($dns_user);

DBIPASS:
print "Your MySQL pass (required): ";
my $dns_password;
while ( $dns_password = <> ) {
    chomp($dns_password);
    if ($dns_password) {
        last;
    } else {
        goto DBIPASS;
    }
}

eval {
    $dbh = DBI->connect( "dbi:mysql:database=foorum;host=$dns_host;port=3306",
        $dns_user, $dns_password, { RaiseError => 1, PrintError => 1 } )
        or die $DBI::errstr;
};
if ($@) {
    print "\nError:\n", $@, "\nPlease try it again\n\n";
    goto DBI;
}

print "Set your site domain which will be used in cron email.\n";
print "Your site domain (http://www.foorumbbs.com/ by default): ";
my $domain = <>;
chomp($domain);
$domain = 'http://www.foorumbbs.com/' unless ($domain);
$domain .= '/';
$domain =~ s/\/+$/\//isg;

my $yaml;
if ( -e "$path/foorum_local.yml" ) {
    $yaml = LoadFile("$path/foorum_local.yml");
}

$yaml->{dsn}             = "dbi:mysql:database=foorum;host=$dns_host;port=3306";
$yaml->{dsn_user}        = $dns_user;
$yaml->{dsn_pwd}         = $dns_password;
$yaml->{theschwartz_dsn} = "dbi:mysql:database=theschwartz;host=$dns_host;port=3306";
$yaml->{site}->{domain}  = $domain;

print "\n\nSaving ....\n";
DumpFile( "$path/foorum_local.yml", $yaml );

print "Attention! The first user created will be site admin automatically!\n";
my $sql = q~INSERT INTO user_role SET user_id = 1, role = 'admin', field = 'site'~;
$dbh->do($sql) or die $DBI::errstr;
print "[OK] ", $sql, "\n";

print "=" x 50, "\nDone!\n", "Thanks For Join US!\n";
