#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 10;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::TestUtils qw/schema cache base_path/;
use Foorum::Utils qw/encodeHTML/;
my $schema = schema();
my $cache  = cache();

my $forum_res = $schema->resultset('Forum');

# create a new forum
$forum_res->create(
    {   forum_id      => 1,
        forum_code    => 'test1111',
        name          => 'FoorumTest',
        description   => 'desc',
        forum_type    => 'classical',
        policy        => 'public',
        total_members => 1
    }
);
$schema->resultset('ForumSettings')->create(
    {   forum_id => 1,
        type     => 'can_post_threads',
        value    => 'N',
    }
);
$cache->remove("forum|forum_id=1");

# test get
my $forum  = $forum_res->get(1);            # by forum_id;
my $forum2 = $forum_res->get('test1111');
is_deeply( $forum, $forum2, 'get by forum_id and forum_code is the same' );
is( $forum->{forum_type}, 'classical',       'forum_type OK' );
is( $forum->{policy},     'public',          'policy OK' );
is( $forum->{name},       'FoorumTest',      'name OK' );
is( $forum->{forum_url},  '/forum/test1111', 'forum_url OK' );

# test forum_settings
is( $forum->{settings}->{can_post_threads}, 'N', 'settings can_post_threads OK' );

# test update
$forum_res->update_forum( 1, { name => 'FoorumTest2', forum_code => 'test2222' } );
$forum  = $forum_res->get(1);            # by forum_id;
$forum2 = $forum_res->get('test2222');
is_deeply( $forum, $forum2,
    'get by forum_id and forum_code is the same after update_forum' );
is( $forum->{name},      'FoorumTest2',     'name OK after update_forum' );
is( $forum->{forum_url}, '/forum/test2222', 'forum_url OK after update_forum' );

# test remove
$forum_res->remove_forum(1);
my $count = $forum_res->count( { forum_id => 1 } );
is( $count, 0, 'remove OK' );

END {

    # Keep Database the same from original
    use File::Copy ();
    my $base_path = base_path();
    File::Copy::copy(
        File::Spec->catfile( $base_path, 't', 'lib', 'Foorum', 'backup.db' ),
        File::Spec->catfile( $base_path, 't', 'lib', 'Foorum', 'test.db' )
    );
}

1;
