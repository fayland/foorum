#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use FindBin qw/$RealBin $Bin/;
use Cwd qw/abs_path/;
use lib "$Bin/lib";
use Foorum::TestUtils qw/base_path schema cache/;
use File::Spec;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;
my $real = abs_path( File::Spec->catdir( $RealBin, '..' ) );
is( $base_path, $real, 'base_path OK' );

my $schema = schema();
my $scache = $schema->cache();
isa_ok( $schema, 'Foorum::Schema',   'schema() ISA Foorum::Schema' );
isa_ok( $scache, 'Cache::FileCache', 'schema->cache() ISA Cache::FileCache' );

my $cache = cache();
isa_ok( $cache, 'Cache::FileCache', 'cache() ISA Cache::FileCache' );

#diag($base_path);
