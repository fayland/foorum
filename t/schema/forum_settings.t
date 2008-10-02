#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    $ENV{TEST_FOORUM} = 1;
    plan tests => 2;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache/;
use Foorum::TestUtils qw/rollback_db/;
use Foorum::Utils qw/encodeHTML/;
my $schema = schema();
my $cache  = cache();

my $forum_res = $schema->resultset('Forum');
my $forum_settings_res = $schema->resultset('ForumSettings');

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
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'can_post_threads',
        value    => 'N',
    }
);
$forum_settings_res->create(
    {   forum_id => 1,
        type     => 'create_time',
        value    => '123456',
    }
);
$cache->remove("forum|forum_id=1");

# test get
my $forum  = $forum_res->get(1);            # by forum_id;

# get all forum_settings
my $settings = $forum_settings_res->get_forum_settings( $forum, { all => 1 } );
is( scalar keys %$settings, 2, 'get 2 settings' );
is_deeply(
    $settings,
    {   can_post_threads => 'N',
        create_time      => 123456
    },
    'get_forum_settings all => 1 OK'
);

END {

    # Keep Database the same from original
    rollback_db();
}

1;
