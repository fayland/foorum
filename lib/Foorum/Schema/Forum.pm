package Foorum::Schema::Forum;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("forum");
__PACKAGE__->add_columns(
  "forum_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "forum_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 25,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "description",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "forum_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "policy",
  { data_type => "ENUM", default_value => "public", is_nullable => 0, size => 9 },
  "total_members",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 8 },
  "total_topics",
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
  "last_post_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("forum_id");
__PACKAGE__->add_unique_constraint("forum_code", ["forum_code"]);

__PACKAGE__->has_many(
    'topics' => 'Foorum::Schema::Topic',
    { 'foreign.forum_id' => 'self.forum_id' }
);

use Foorum::Formatter qw/filter_format/;

sub get : ResultSet {
    my ( $self, $forum_code ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # if $forum_code is all numberic, that's forum_id
    # or else, it's forum_code

    my $forum;    # return value
    my $forum_id = 0;
    if ( $forum_code =~ /^\d+$/ ) {
        $forum_id = $forum_code;
    } else {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $cache->get($mem_key);
        if ( $mem_val and $mem_val->{$forum_code} ) {
            $forum_id = $mem_val->{$forum_code};
        } else {
            $forum = $self->search( { forum_code => $forum_code } )->first;
            return unless $forum;
            $forum_id = $forum->forum_id;
            $mem_val->{$forum_code} = $forum_id;
            $cache->set( $mem_key, $mem_val, 36000 );    # 10 hours

            # set cache
            $forum              = $forum->{_column_data};              # hash for cache
            $forum->{settings}  = $self->get_forum_settings($forum);
            $forum->{forum_url} = $self->get_forum_url($forum);
            $cache->set( "forum|forum_id=$forum_id", { val => $forum, 1 => 2 }, 7200 );
        }
    }

    return unless ($forum_id);

    unless ($forum) {    # do not get from convert forum_code to forum_id
        my $cache_key = "forum|forum_id=$forum_id";
        my $cache_val = $cache->get($cache_key);

        if ( $cache_val and $cache_val->{val} ) {
            $forum = $cache_val->{val};
        } else {
            $forum = $self->find( { forum_id => $forum_id } );
            return unless ($forum);

            # set cache
            $forum              = $forum->{_column_data};              # hash for cache
            $forum->{settings}  = $self->get_forum_settings($forum);
            $forum->{forum_url} = $self->get_forum_url($forum);
            $cache->set( "forum|forum_id=$forum_id", { val => $forum, 1 => 2 }, 7200 );
        }
    }

    return $forum;
}

sub get_forum_url : ResultSet {
    my ( $self, $forum ) = @_;

    my $forum_url = '/forum/' . $forum->{forum_code};

    return $forum_url;
}

sub get_forum_settings : ResultSet {
    my ( $self, $forum ) = @_;

    my $schema   = $self->result_source->schema;
    my $forum_id = $forum->{forum_id};

    # get forum settings
    my $settings_rs
        = $schema->resultset('ForumSettings')->search( { forum_id => $forum_id } );
    my $settings = {    # default
        can_post_threads => 'Y',
        can_post_replies => 'Y',
        can_post_polls   => 'Y'
    };
    while ( my $r = $settings_rs->next ) {
        $settings->{ $r->type } = $r->value;
    }

    return $settings;
}

sub update_forum : ResultSet {
    my ( $self, $forum_id, $update ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { forum_id => $forum_id } )->update($update);

    $cache->remove("forum|forum_id=$forum_id");

    if ( $update->{forum_code} ) {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $cache->get($mem_key);
        $mem_val->{ $update->{forum_code} } = $forum_id;
        $cache->set( $mem_key, $mem_val, 36000 );    # 10 hours
    }
}

sub remove_forum : ResultSet {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    $self->search( { forum_id => $forum_id, } )->delete;
    $schema->resultset('LogAction')->search( { forum_id => $forum_id } )->delete;

    # remove user_forum
    $schema->resultset('UserForum')->search( { forum_id => $forum_id } )->delete;

    # get all topic_ids
    my @topic_ids;
    my $tp_rs = $schema->resultset('Topic')
        ->search( { forum_id => $forum_id, }, { columns => ['topic_id'], } );
    while ( my $r = $tp_rs->next ) {
        push @topic_ids, $r->topic_id;
    }
    $schema->resultset('Topic')->search( { forum_id => $forum_id, } )->delete;

    # get all poll_ids
    my @poll_ids;
    my $pl_rs = $schema->resultset('Poll')
        ->search( { forum_id => $forum_id, }, { columns => ['poll_id'], } );
    while ( my $r = $pl_rs->next ) {
        push @poll_ids, $r->poll_id;
    }
    $schema->resultset('Poll')->search( { forum_id => $forum_id, } )->delete;
    if ( scalar @poll_ids ) {
        $schema->resultset('PollOption')->search( { poll_id => { 'IN', \@poll_ids }, } )
            ->delete;
        $schema->resultset('PollResult')->search( { poll_id => { 'IN', \@poll_ids }, } )
            ->delete;
    }

    # comment and star/share
    if ( scalar @topic_ids ) {
        $schema->resultset('Comment')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
        $schema->resultset('Star')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
        $schema->resultset('Share')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
    }
    if ( scalar @poll_ids ) {
        $schema->resultset('Comment')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
        $schema->resultset('Star')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
        $schema->resultset('Share')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
    }

    # for upload
    $schema->resultset('Upload')->remove_for_forum($forum_id);
}

sub merge_forums : ResultSet {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $from_id = $info->{from_id} or return 0;
    my $to_id   = $info->{to_id}   or return 0;

    my $old_forum = $self->find( { forum_id => $from_id } );
    return unless ($old_forum);
    my $new_forum = $self->find( { forum_id => $to_id } );
    return unless ($new_forum);
    $self->search( { forum_id => $from_id, } )->delete;

    # update new
    my $total_topics  = $old_forum->total_topics;
    my $total_replies = $old_forum->total_replies;
    my $total_members = $old_forum->total_members;
    my @extra_cols;
    if ( $new_forum->policy eq 'private' ) {
        @extra_cols = ( 'total_members', \"total_members + $total_members" );    #"
    }
    $self->search( { forum_id => $to_id, } )->update(
        {   total_topics  => \"total_topics  + $total_topics",
            total_replies => \"total_replies + $total_replies",
            @extra_cols,
        }
    );

    # remove user_forum
    $schema->resultset('UserForum')->search( { forum_id => $from_id } )->delete;

    # topics
    $schema->resultset('Topic')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # FIXME!!!
    # need delete all topic_id cache object
    # $=cache->remove("topic|topic_id=$topic_id");

    # polls
    $schema->resultset('Poll')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # comment
    $schema->resultset('Comment')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # for upload
    $schema->resultset('Upload')->change_for_forum($info);

    return 1;
}

sub get_announcement : ResultSet {
    my ( $self, $forum ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $forum_id = $forum->{forum_id};

    my $memkey = "forum|announcement|forum_id=$forum_id";
    my $memval = $cache->get($memkey);
    if ( $memval and $memval->{value} ) {
        $memval = $memval->{value};
    } else {
        my $rs           = $schema->resultset('Comment');
        my $announcement = $rs->search(
            {   object_type => 'announcement',
                object_id   => $forum_id,
            },
            { columns => [ 'title', 'text', 'formatter' ], }
        )->first;

        # filter format by Foorum::Filter
        if ($announcement) {
            $announcement = $announcement->{_column_data};
            $announcement->{text} = filter_format( $announcement->{text},
                { format => $announcement->{formatter} } );
        }
        $memval = $announcement;
        $cache->set( $memkey, { value => $memval, 1 => 2 } );
    }

    return $memval;
}

1;
