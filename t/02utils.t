#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

use Foorum::Utils qw/datetime_to_tt2_acceptable truncate_text/;

# test datetime_to_tt2_acceptable
my $datetime = '2007-12-21 08:09:01';
my $ret      = datetime_to_tt2_acceptable($datetime);
is( $ret, '8:9:1 21/12/2007', 'datetime_to_tt2_acceptable OK' );

# test truncate_text
my $text = "Hello, 请截取我";
my $text2 = truncate_text($text, 8);
is($text2, "Hello, 请 ...", 'truncate_text 8 OK');
$text2 = truncate_text($text, 9);
is($text2, "Hello, 请截 ...", 'truncate_text 9 OK');
$text2 = truncate_text($text, 10);
is($text2, "Hello, 请截取 ...", 'truncate_text 10 OK');

1;