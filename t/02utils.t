#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 18;

use Foorum::Utils qw/
    encodeHTML decodeHTML
    is_color
    generate_random_word
    get_page_from_url
    datetime_to_tt2_acceptable
    truncate_text
    /;

# test encodeHTML and decodeHTML
{
    my $html = encodeHTML('<test> with & and "');
    is( $html, "&lt;test&gt; with &amp; and &quot;", 'encodeHTML OK' );
    my $text = decodeHTML("&lt;test&gt; with &amp; and &quot;");
    is( $text, '<test> with & and "', 'decodeHTML OK' );
}

# test is_color
{
    my $ret = is_color('#FF0000');
    is( $ret, 1, 'test is_color with 1' );
    $ret = is_color("test");
    is( $ret, 0, 'test is_color with 0' );
}

# test generate_random_word
{
    my $ret = generate_random_word(8);
    is( length($ret), 8, 'generate_random_word length OK' );
    like( $ret, qr/^[A-Za-z0-9]{8}$/, 'generate_random_word all are A-Za-z0-9' );
}

# test get_page_from_url
{
    my $page = get_page_from_url("/test/page=2");
    is( $page, 2, 'get_page_from_url with page=2' );
    $page = get_page_from_url("/test/page=3/with_slash");
    is( $page, 3, 'get_page_from_url with page=3/' );
    $page = get_page_from_url("/test/nothing");
    is( $page, 1, 'get_page_from_url return default 1' );
}

# test datetime_to_tt2_acceptable
{
    my $datetime = '2007-12-21 08:09:01';
    my $ret      = datetime_to_tt2_acceptable($datetime);
    is( $ret, '8:9:1 21/12/2007', 'datetime_to_tt2_acceptable OK' );
}

# test truncate_text
{
    my $text = "Hello, 请截取我";
    my $text2 = truncate_text( $text, 8 );
    is( $text2, "Hello, 请 ...", 'truncate_text 8 OK' );
    $text2 = truncate_text( $text, 9 );
    is( $text2, "Hello, 请截 ...", 'truncate_text 9 OK' );
    $text2 = truncate_text( $text, 10 );
    is( $text2, "Hello, 请截取 ...", 'truncate_text 10 OK' );
}

1;
