#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";

    plan tests => 20;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache base_path/;
use Foorum::Utils qw/encodeHTML/;
my $schema = schema();
my $cache  = cache();

my $comment_res = $schema->resultset('Comment');

# test create_comment
sub create_comment {
    my ( $comment_id, $reply_to ) = @_;
    $comment_res->create(
        {   comment_id  => $comment_id,
            object_type => 'test',
            object_id   => 22,
            forum_id    => 1,
            upload_id   => 0,
            reply_to    => $reply_to,
            title       => encodeHTML("$comment_id - $reply_to <title>"),
            text        => "$comment_id x $reply_to x foorumbbs",
            formatter   => 'plain',
            author_id   => 1,
            post_ip     => '127.0.0.1',
            post_on => \'CURRENT_TIMESTAMP',    # For SQLite
        }
    );
}
&create_comment( 1, 0 );
my $cache_key = "comment|object_type=test|object_id=22";
$cache->remove($cache_key);

# test get
my $comment = $comment_res->get( 1, { with_text => 1 } );
isn't( $comment, undef, 'get OK' );
is( $comment->{object_type}, 'test', 'get object_type OK' );
is( $comment->{title}, '1 - 0 &lt;title&gt;', 'get encodeHTML title OK' );
is( $comment->{text},  '1 x 0 x foorumbbs' );

# test remove_one_item
my $ok = $comment_res->remove_one_item($comment);
is( $ok, 1, 'remove_one_item return value OK' );

my $count = $comment_res->count( { comment_id => 1 } );
is( $count, 0, 'delete confirmed' );

# test get_all_comments_by_object
&create_comment( 1, 0 );
&create_comment( 2, 1 );
&create_comment( 3, 1 );
&create_comment( 4, 2 );
$cache->remove($cache_key);

my @comments = $comment_res->get_all_comments_by_object( 'test', 22 );
is( scalar @comments,           4, 'get_all_comments_by_object OK' );
is( $comments[0]->{comment_id}, 1, 'comments[0]->{comment_id} == 1' );
is( $comments[1]->{comment_id}, 2, 'comments[1]->{comment_id} == 2' );
is( $comments[2]->{comment_id}, 3, 'comments[2]->{comment_id} == 3' );
is( $comments[3]->{comment_id}, 4, 'comments[3]->{comment_id} == 4' );

# test get_children_comments
my @result_comments;
$comment_res->get_children_comments( 1, 1, \@comments, \@result_comments );
is( scalar @result_comments,           3, 'get_children_comments OK' );
is( $result_comments[0]->{comment_id}, 2, 'get_children_comments first node OK' );
is( $result_comments[0]->{level},      1, 'get_children_comments level 1 OK' );
is( $result_comments[1]->{comment_id}, 4, 'get_children_comments second node OK' );
is( $result_comments[1]->{level},      2, 'get_children_comments level 2 OK' );
is( $result_comments[2]->{comment_id}, 3, 'get_children_comments third node OK' );
is( $result_comments[2]->{level},      1, 'get_children_comments level 1 OK' );

# test remove_children
my $deleted_count = $comment_res->remove_children( $comments[1] );
is( $deleted_count, 2, 'remove_children OK' );
$count = $comment_res->count( { object_type => 'test', object_id => 22 } );
is( $count, 2, 'after remove_children, count OK' );

=pod

# test remove_by_object
$deleted_count = $comment_res->remove_by_object('test', 22);
is($deleted_count, 2, 'remove_by_object OK');
$count = $comment_res->count( { object_type => 'test', object_id => 22 } );
is($count, 0, 'after remove_by_object, count OK');

=cut

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;
