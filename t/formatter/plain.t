#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require URI::Find }
        or plan skip_all => "URI::Find is required for this test";

    plan tests => 2;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
hello body.

http://fayland.org/
<a href="http://fayland.org">fayland.org</a>
TEXT

my $html = filter_format($text);

like( $html, qr/\<br/,      'linebreak OK' );
like( $html, qr/\<a href=/, 'http://fayland.org/ URI::Find OK' );

#diag($html);
