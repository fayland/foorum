package Foorum::Model::Topic;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub get {
    my ( $self, $c, $topic_id, $attrs ) = @_;

    my $cache_key   = "topic|topic_id=$topic_id";
    my $cache_value = $c->cache->get($cache_key);

    my $topic;
    if ($cache_value and $cache_value->{val}) {
        $topic = $cache_value->{val};
    } else {
        $topic = $c->model('DBIC')->resultset('Topic')->find( { topic_id => $topic_id } );
        return unless ($topic);
        $topic = $topic->{_column_data}; # for cache
        $c->cache->set($cache_key, { val => $topic, 1 => 2 }, 7200);
    }

    if ($attrs->{with_author}) {
        $topic->{author} = $c->model('User')->get($c, { user_id => $topic->{author_id} });
    }

    return $topic;
}

sub update {
    my ($self, $c, $topic_id, $update) = @_;
    
    $c->model('DBIC')->resultset('Topic')->search( { topic_id => $topic_id } )->update($update);
    
    $c->cache->delete("topic|topic_id=$topic_id");
}

sub remove {
    my ( $self, $c, $forum_id, $topic_id, $info ) = @_;

    # delete topic
    $c->model('DBIC::Topic')->search( { topic_id => $topic_id } )->delete;
    $c->cache->delete("topic|topic_id=$topic_id");

    # delete comments with upload
    my $total_replies = -1;    # since one comment is topic indeed.
    my $comment_rs = $c->model('DBIC::Comment')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    );
    while ( my $comment = $comment_rs->next ) {
        $c->model('Comment')->remove( $c, $comment );
        $total_replies++;
    }

    # log action
    $c->model('Log')->log_action(
        $c,
        {   action      => 'delete',
            object_type => 'topic',
            object_id   => $topic_id,
            forum_id    => $forum_id,
            text        => $info->{log_text}
        }
    );

    # update last
    my $lastest
        = $c->model('DBIC')->resultset('Topic')
        ->search( { forum_id => $forum_id },
        { order_by => 'last_update_date DESC', } )->first;
    my $last_post_id = $lastest ? $lastest->topic_id : 0;
    $c->model('Forum')->update( $c, $forum_id, 
        {   total_topics  => \'total_topics - 1',
            last_post_id  => $last_post_id,
            total_replies => \"total_replies - $total_replies",
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
