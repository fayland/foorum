#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";

    plan tests => 23;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema base_path/;

my $schema = schema();

use Foorum::Search;

my $search = new Foorum::Search;

# use database
$search->{sphinx}       = undef;
$search->{use_sphinx}   = 0;
$search->{db}->{schema} = $schema;

##################################
# Forum Tests
##################################

# insert data first
my $create = {
    topic_id         => 1,
    forum_id         => 1,
    title            => 'test title',
    closed           => 0,
    author_id        => 1,
    last_updator_id  => 1,
    last_update_date => time() - 200,
    post_on          => time(),
};
$schema->resultset('Topic')->create_topic($create);
$create = {
    topic_id         => 2,
    forum_id         => 2,
    title            => 'test again',
    closed           => 0,
    author_id        => 1,
    last_updator_id  => 2,
    last_update_date => time() - 100,
    post_on          => time() - 100,
};
$schema->resultset('Topic')->create_topic($create);
$create = {
    topic_id         => 3,
    forum_id         => 2,
    title            => 'no again',
    closed           => 0,
    author_id        => 2,
    last_updator_id  => 3,
    last_update_date => time(),
    post_on          => time() - 200,
};
$schema->resultset('Topic')->create_topic($create);

my $ret = $search->query( 'topic', { author_id => 1 } );
is( $ret->{error},               undef, '[0]no error in database' );
is( scalar @{ $ret->{matches} }, 2,     '[0]get 2 results' );
is( $ret->{matches}->[0],        2,     '[0]matches[0] is topic 2' );
is( $ret->{matches}->[1],        1,     '[0]matches[1] is topic 1' );
isa_ok( $ret->{pager}, 'Data::Page', '[0]pager is ISA Data::Page' );
is( $ret->{pager}->total_entries, 2, '[0]pager OK' );

# add order_by
$ret = $search->query( 'topic', { author_id => 1, order_by => 'post_on' } );
is( $ret->{error},               undef, '[0+]no error in database' );
is( scalar @{ $ret->{matches} }, 2,     '[0+]get 2 results' );
is( $ret->{matches}->[0],        1,     '[0+]matches[0] is topic 2' );
is( $ret->{matches}->[1],        2,     '[0+]matches[1] is topic 1' );

$ret = $search->query( 'topic', { title => 'test' } );
is( $ret->{error},                undef, '[1]no error in database' );
is( scalar @{ $ret->{matches} },  2,     '[1]get 2 results' );
is( $ret->{matches}->[0],         2,     '[1]matches[0] is topic 2' );
is( $ret->{matches}->[1],         1,     '[1]matches[1] is topic 1' );
is( $ret->{pager}->total_entries, 2,     '[1]pager OK' );

$ret = $search->query( 'topic', { title => 'again' } );
is( $ret->{error},                undef, '[2]no error in database' );
is( scalar @{ $ret->{matches} },  2,     '[2]get 2 results' );
is( $ret->{matches}->[0],         3,     '[2]matches[0] is topic 3' );
is( $ret->{matches}->[1],         2,     '[2]matches[1] is topic 2' );
is( $ret->{pager}->total_entries, 2,     '[2]pager OK' );

$ret = $search->query( 'topic', { author_id => 1, forum_id => 1 } );
is( $ret->{error},                undef, '[3]no error in database' );
is( scalar @{ $ret->{matches} },  1,     '[3]get 1 results' );
is( $ret->{pager}->total_entries, 1,     '[3]pager OK' );

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
