package Foorum::Schema::Topic;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("topic");
__PACKAGE__->add_columns(
  "topic_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "closed",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "sticky",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "elite",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "hit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "last_updator_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "last_update_date",
  {
    data_type => "INT",
    default_value => 0,
    is_nullable => 1,
    size => 11,
  },
  "author_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "total_replies",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "status",
  {
    data_type => "ENUM",
    default_value => "healthy",
    is_nullable => 0,
    size => 7,
  },
);
__PACKAGE__->set_primary_key("topic_id");

__PACKAGE__->might_have(
    'author' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.author_id' }
);
__PACKAGE__->might_have(
    'last_updator' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.last_updator_id' }
);
__PACKAGE__->belongs_to(
    'forum' => 'Foorum::Schema::Forum',
    { 'foreign.forum_id' => 'self.forum_id' }
);

sub get : ResultSet  {
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

sub create_topic : ResultSet  {
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

sub update_topic : ResultSet  {
    my ( $self, $topic_id, $update ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { topic_id => $topic_id } )->update($update);

    $cache->remove("topic|topic_id=$topic_id");
}

sub remove : ResultSet  {
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
            time        => time(),
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
