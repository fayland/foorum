#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
 :inlove: [b]Test[/b] [url=http://fayland/]da[/url]
TEXT

my $html = filter_format( $text, { format => 'ubb' } );

like( $html, qr/inlove.gif/, 'emot convert OK' );
like( $html, qr/\<a href/,   '[url] convert OK' );
like( $html, qr/\<b\>/,       '[b] convert OK' );

# check http://code.google.com/p/foorum/issues/detail?id=36
$text = <<TEXT;
[url=http://search.cpan.org/perldoc?Catalyst::Foorum]Catalyst::Foorum[/url]
TEXT
$html = filter_format( $text, { format => 'ubb' } );
is($html, '<p><a href="http://search.cpan.org/perldoc?Catalyst::Foorum">Catalyst::Foorum</a></p>', 'CPAN URL OK');

#diag($html);
