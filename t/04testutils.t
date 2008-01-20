#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw/$RealBin $Bin/;
use Cwd qw/abs_path/;
use lib "$Bin/lib";
use Foorum::TestUtils qw/base_path/;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;

my $real = abs_path("$RealBin/../");

is( $base_path, $real, 'abs_path OK' );

#diag($base_path);
