#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBI }
        or plan skip_all => "DBI is required for this test";
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 6;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache/;
my $schema = schema();
my $cache  = cache();

my $comment_res = $schema->resultset('Comment');

# test create_comment
my $new_comment = $comment_res->create_comment(
    {   coment_id   => 1,
        object_type => 'test',
        object_id   => 22,
        forum_id    => 1,
        upload_id   => 0,
        reply_to    => 0,
        title       => '<title>',
        text        => '[http://www.foorumbbs.com/]',
        formatter   => 'wiki',
        user_id     => 1,
        post_ip     => '127.0.0.1',
        lang        => 'en',
        post_on     => \'CURRENT_TIMESTAMP', # For SQLite
    }
);

# test get
my $comment = $comment_res->get(1, { with_text => 1 } );
isn't($comment, undef, 'get OK');
is($comment->{object_type}, 'test', 'get object_type OK');
is($comment->{title}, '&lt;title&gt;', 'get encodeHTML title OK');
is($comment->{text}, '<p><a href="http://www.foorumbbs.com/" rel="nofollow">http://www.foorumbbs.com/</a></p>');

# test remove_one_item
my $ok = $comment_res->remove_one_item($comment);
is($ok, 1, 'remove_one_item return value OK');

my $count = $comment_res->count( { comment_id => 1 } );
is($count, 0, 'delete confirmed');

1;
