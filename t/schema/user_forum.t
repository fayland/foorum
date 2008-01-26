#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 5;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema base_path/;
my $schema = schema();

my $userforum_res = $schema->resultset('UserForum');

# test create
$userforum_res->create_user_forum(
    {   user_id  => 1,
        forum_id => 999,
        status   => 'admin',
    }
);
my $data = $userforum_res->search( { forum_id => 999 } )->first;
is( $data->user_id, 1,       'user_id OK' );
is( $data->status,  'admin', 'status OK' );

# test get_forum_admin
my $user = $userforum_res->get_forum_admin(999);
isnt( $user, undef, 'get_forum_admin OK' );
is( $user->{user_id}, 1, 'user_id is 1' );

# test remove_user_forum
$userforum_res->remove_user_forum(
    {   user_id  => 1,
        forum_id => 999
    }
);
my $cnt = $userforum_res->count( { forum_id => 999 } );
is( $cnt, 0, 'after remove_user_forum OK' );

# Keep Database the same from original
use File::Copy ();

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
