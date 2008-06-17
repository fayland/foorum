#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 3;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache base_path/;
my $schema = schema();
my $cache  = cache();

my $filter_word_res = $schema->resultset('FilterWord');

# create
$filter_word_res->create(
    {   word => 'system',
        type => 'username_reserved'
    }
);
$filter_word_res->create(
    {   word => 'fuck',
        type => 'bad_word'
    }
);
$filter_word_res->create(
    {   word => 'asshole',
        type => 'offensive_word'
    }
);

$cache->remove("filter_word|type=username_reserved");
$cache->remove("filter_word|type=bad_word");
$cache->remove("filter_word|type=offensive_word");

my @data = $filter_word_res->get_data('username_reserved');

ok( grep { $_ eq 'system' } @data, "get 'username_reserved' OK" );

my $has_bad_word = $filter_word_res->has_bad_word("oh, fuck you!");
is( $has_bad_word, 'fuck', 'has_bad_word OK' );

my $return_text = $filter_word_res->convert_offensive_word("kick your asshole la, dude!");
like( $return_text, qr/\*/, 'convert_offensive_word OK' );

END {

    # Keep Database the same from original
    use File::Copy ();

    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
