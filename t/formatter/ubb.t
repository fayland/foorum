#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
 :inlove: [b]Test[/b] [url=http://fayland/]da[/url]
TEXT

my $html = filter_format( $text, { format => 'ubb' } );

like( $html, qr/inlove.gif/, 'emot convert OK' );
like( $html, qr/\<a href/,   '[url] convert OK' );
like( $html, qr/\<b\>/,       '[b] convert OK' );

#diag($html);
