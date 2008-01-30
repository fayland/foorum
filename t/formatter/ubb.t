#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;

use Foorum::Formatter qw/filter_format/;

TODO: {
    local $TODO = 'use HTML::BBCode or HTML::BBCode::Strict';

    my $text = <<TEXT;
     :inlove: [b]Test[/b] [url=http://fayland.org/]Personal Homepage[/url] [size=14]size[/size]
    [font=Arial]Arial Text[/font]
TEXT
    
    my $html = filter_format( $text, { format => 'ubb' } );
    
    like( $html, qr/inlove.gif/,               'emot convert OK' );
    like( $html, qr/\<a href/,                 '[url] convert OK' );
    like( $html, qr/\<b\>/,                    '[b] convert OK' );
    like( $html, qr/14pt/,                     '[size] OK' );
    like( $html, qr/font-family\s*\:\s*Arial/, '[font] OK' );
    
    #diag($html);
    
    # check http://code.google.com/p/foorum/issues/detail?id=36
    $text = <<TEXT;
    [url=http://search.cpan.org/perldoc?CatalystX::Foorum]CatalystX::Foorum[/url]
TEXT
    $html = filter_format( $text, { format => 'ubb' } );
    is( $html,
        '<p><a href="http://search.cpan.org/perldoc?CatalystX::Foorum">CatalystX::Foorum</a></p>',
        'CPAN URL OK'
    );

}

1;
