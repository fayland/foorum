#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Foorum::XUtils qw/base_path/;
use File::Spec;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;
my $real = abs_path( File::Spec->catdir( $RealBin, '..' ) );
is( $base_path, $real, 'base_path OK' );

#diag($base_path);
