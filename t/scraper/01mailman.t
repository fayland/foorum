#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;

BEGIN {

    eval { require HTML::TokeParser::Simple }
        or plan skip_all => "HTML::TokeParser::Simple is required for this test";
    eval { require LWP::Simple }
        or plan skip_all => "LWP::Simple is required for this test";

    plan tests => 2;
}

use Foorum::Scraper::MailMan;

my $mailman = new Foorum::Scraper::MailMan;

open( my $fh, '<', "$Bin/01mailman/001126.html" );
local $/ = undef;
flock( $fh, 2 );
my $html = <$fh>;
close($fh);

my ( undef, $ret ) = $mailman->extract_from_message($html);

#diag($ret);

like( $ret, qr/everything is nothing/, 'extract_from_message ok' );

open( $fh, '<', "$Bin/01mailman/thread.html" );
local $/ = undef;
flock( $fh, 2 );
$html = <$fh>;
close($fh);

$mailman->{url_base} = '';
$ret = $mailman->extract_from_thread($html);
is( scalar @$ret, 6, 'extract_from_thread OK' );

#use Data::Dumper;
#diag(Dumper($ret));
