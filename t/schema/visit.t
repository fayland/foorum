#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 3;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema base_path/;

my $schema = schema();

my $visit_res = $schema->resultset('Visit');

# test make_visited
$visit_res->make_visited( 'test', 1, 2 );
my $count = $visit_res->count( { object_type => 'test', object_id => 1, user_id => 2 } );
is( $count, 1, 'make_visited OK' );

# test is_visited
my $ret = $visit_res->is_visited( 'test', 1, 2 );
is_deeply( $ret, { test => { 1 => 1 } }, 'is_visited OK' );

# test make_un_visited
$visit_res->make_un_visited( 'test', 1 );
$count = $visit_res->count( { object_type => 'test', object_id => 1, user_id => 2 } );
is( $count, 0, 'make_visited OK' );

# Keep Database the same from original
use File::Copy ();

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
