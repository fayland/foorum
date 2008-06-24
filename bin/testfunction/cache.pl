#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/cache/;

my $cache = cache();

my $key = 'Foorum:testfunction:cache.pl';
my $val = scalar( localtime() );

$cache->set( $key, $val, 60 );

my $ret = $cache->get($key);
print "set $val and get $val\n";

$cache->remove($key);
$ret = $cache->get($key);
print "after delete, we get $ret\n";

1;
