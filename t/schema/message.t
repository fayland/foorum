#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 4;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache base_path/;

my $schema = schema();
my $cache  = cache();

my $message_res = $schema->resultset('Message');

# create
my $message = $message_res->create(
    {   message_id  => 1,
        from_id     => 2,
        to_id       => 1,
        title       => 'Test',
        text        => 'Text',
        post_on     => "2008-01-20",
        post_ip     => '127.0.0.1',
        from_status => 'open',
        to_status   => 'open',
    }
);

# add unread
$schema->resultset('MessageUnread')->create(
    {   message_id => $message->message_id,
        user_id    => 1,
    }
);
$cache->remove('global|message_unread_cnt|user_id=1');

my $cnt = $message_res->get_unread_cnt(1);
is( $cnt, 1, 'get_unread_cnt OK' );

my $messages = $message_res->are_messages_unread( 1, [ $message->message_id ] );
is_deeply( $messages, { $message->message_id => 1 }, 'are_messages_unread OK' );

$message_res->remove_from_db( $message->message_id );
my $count = $message_res->count( { from_id => 2, to_id => 1 } );
is( $count, 0, 'deleted OK' );
$count = $schema->resultset('MessageUnread')->count( { user_id => 1 } );
is( $count, 0, 'message_unread OK' );

# Keep Database the same from original
use File::Copy ();

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
