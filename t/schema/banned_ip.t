#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBI }
        or plan skip_all => "DBI is required for this test";
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 2;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache/;
my $schema = schema();
my $cache  = cache();

my $banned_ip_res = $schema->resultset('BannedIp');

# create
$banned_ip_res->create(
    {   cidr_ip => '192.168.0.0/24',
        time    => time()
    }
);
$banned_ip_res->create(
    {   cidr_ip => '192.168.1.0/24',
        time    => time()
    }
);

$cache->remove('global|banned_ip');
my @ips = $banned_ip_res->get();

ok( grep { $_ eq '192.168.0.0/24' } @ips, "get '192.168.0.0/24'" );
ok( grep { $_ eq '192.168.1.0/24' } @ips, "get '192.168.1.0/24'" );

#remove
$banned_ip_res->search(
    {   -or => [
            cidr_ip => '192.168.0.0/24',
            cidr_ip => '192.168.1.0/24'
        ],
    }
)->delete;
$cache->remove('global|banned_ip');

1;
