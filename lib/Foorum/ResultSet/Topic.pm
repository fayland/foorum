package Foorum::ResultSet::Topic;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub get {
    my ( $self, $topic_id, $attrs ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key   = "topic|topic_id=$topic_id";
    my $cache_value = $cache->get($cache_key);

    my $topic;
    if ( $cache_value and $cache_value->{val} ) {
        $topic = $cache_value->{val};
    } else {
        $topic = $self->find( { topic_id => $topic_id } );
        return unless ($topic);
        $topic = $topic->{_column_data};    # for cache
        $cache->set( $cache_key, { val => $topic, 1 => 2 }, 7200 );
    }

    if ( $attrs->{with_author} ) {
        $topic->{author}
            = $schema->resultset('User')->get( { user_id => $topic->{author_id} } );
    }

    return $topic;
}

sub create_topic {
    my ( $self, $create ) = @_;

    my $schema = $self->result_source->schema;

    my $topic = $self->create($create);

    # star it by default
    $schema->resultset('Star')->create(
        {   user_id     => $create->{author_id},
            object_type => 'topic',
            object_id   => $topic->topic_id,
            time        => time(),
        }
    );

    return $topic;
}

sub update_topic {
    my ( $self, $topic_id, $update ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { topic_id => $topic_id } )->update($update);

    $cache->remove("topic|topic_id=$topic_id");
}

sub remove {
    my ( $self, $forum_id, $topic_id, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # delete topic
    $self->search( { topic_id => $topic_id } )->delete;
    $cache->remove("topic|topic_id=$topic_id");

    # delete comments with upload
    my $total_replies
        = $schema->resultset('Comment')->remove_by_object( 'topic', $topic_id );

    # since one comment is topic indeed. so total_replies = delete_counts - 1
    $total_replies-- if ( $total_replies > 0 );

    # delete star/share
    $schema->resultset('Star')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;
    $schema->resultset('Share')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;

    # log action
    my $user_id = $info->{operator_id} || 0;
    $schema->resultset('LogAction')->create(
        {   user_id     => $user_id,
            action      => 'delete',
            object_type => 'topic',
            object_id   => $topic_id,
            time        => $info->{SQLite_NOW} || \'NOW()', # when use SQLite in test
            text        => $info->{log_text} || '',
            forum_id    => $forum_id,
        }
    );

    # update last
    my $lastest = $self->search( { forum_id => $forum_id },
        { order_by => \'last_update_date DESC', columns => ['topic_id'] } )->first;
    my $last_post_id = $lastest ? $lastest->topic_id : 0;
    $schema->resultset('Forum')->update_forum(
        $forum_id,
        {   total_topics  => \"total_topics - 1",
            last_post_id  => $last_post_id,
            total_replies => \"total_replies - $total_replies",
        }
    );
}

1;
__END__
