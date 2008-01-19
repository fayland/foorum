#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

    eval { require HTML::BBCode }
        or plan skip_all => "HTML::BBCode is required for this test";

    plan tests => 4;
}

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
 :inlove: [b]Test[/b] [size=14]dsadsad[/size] [url=http://fayland/]da[/url]
TEXT

my $html = filter_format( $text, { format => 'ubb' } );

like( $html, qr/inlove.gif/, 'emot convert OK' );
like( $html, qr/\<a href/,   '[url] convert OK' );
like( $html, qr/bold/,       '[b] convert OK' );
like( $html, qr/14px/,       '[size] convert OK' );

#diag($html);
