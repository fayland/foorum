package Foorum::Model::Forum;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub get {
    my ( $self, $c, $forum_code, $attr ) = @_;

    # if $forum_code is all numberic, that's forum_id
    # or else, it's forum_code
    
    my $forum; # return value
    my $forum_id = 0;
    if ($forum_code =~ /^\d+$/) {
        $forum_id = $forum_code;
    } else {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $c->cache->get($mem_key);
        if ($mem_val and $mem_val->{$forum_code}) {
            $forum_id = $mem_val->{$forum_code};
        } else {
            $forum = $c->model('DBIC')->resultset('Forum')->search( { forum_code => $forum_code } )->first;
            return unless $forum;
            $forum_id = $forum->forum_id;
            $mem_val->{$forum_code} = $forum_id;
            $c->cache->set($mem_key, $mem_val, 36000); # 10 hours
            
            # set cache
            $forum = $forum->{_column_data}; # hash for cache
            $forum->{forum_url} = $self->get_forum_url( $c, $forum );
            $c->cache->set("forum|forum_id=$forum_id", { val => $forum, 1 => 2 }, 7200);
        }
    }
    
    return unless ($forum_id);
    
    unless ($forum) { # do not get from convert forum_code to forum_id
        my $cache_key = "forum|forum_id=$forum_id";
        my $cache_val = $c->cache->get($cache_key);
    
        if ($cache_val and $cache_val->{val}) {
            $forum = $cache_val->{val};
        } else {
            $forum = $c->model('DBIC')->resultset('Forum')->find( { forum_id => $forum_id } );
            return unless ($forum);
            
            # set cache
            $forum = $forum->{_column_data}; # hash for cache
            $forum->{forum_url} = $self->get_forum_url( $c, $forum );
            $c->cache->set("forum|forum_id=$forum_id", { val => $forum, 1 => 2 }, 7200);
        }
    }

    return $forum;
}

sub get_forum_url {
    my ( $self, $c, $forum ) = @_;

    my $forum_url = '/forum/' . $forum->{forum_code};

    return $forum_url;
}

sub update {
    my ($self, $c, $forum_id, $update) = @_;
    
    $c->model('DBIC')->resultset('Forum')->search( { forum_id => $forum_id } )->update($update);
    
    $c->cache->delete("forum|forum_id=$forum_id");
    
    if ($update->{forum_code}) {
        my $mem_key = 'global|forum_code_to_id';
        my $mem_val = $c->cache->get($mem_key);
        $mem_val->{$update->{forum_code}} = $forum_id;
        $c->cache->set($mem_key, $mem_val, 36000); # 10 hours
    }
}

sub remove_forum {
    my ( $self, $c, $forum_id ) = @_;

    $c->model('DBIC::Forum')->search( { forum_id => $forum_id, } )->delete;
    $c->model('Policy')->remove_user_role( $c, { field => $forum_id, } );
    $c->model('DBIC::LogAction')->search( { forum_id => $forum_id } )->delete;

    # get all topic_ids
    my @topic_ids;
    my $tp_rs = $c->model('DBIC::Topic')
        ->search( { forum_id => $forum_id, }, { columns => ['topic_id'], } );
    while ( my $r = $tp_rs->next ) {
        push @topic_ids, $r->topic_id;
    }
    $c->model('DBIC::Topic')->search( { forum_id => $forum_id, } )->delete;

    # get all poll_ids
    my @poll_ids;
    my $pl_rs = $c->model('DBIC::Poll')
        ->search( { forum_id => $forum_id, }, { columns => ['poll_id'], } );
    while ( my $r = $pl_rs->next ) {
        push @poll_ids, $r->poll_id;
    }
    $c->model('DBIC::Poll')->search( { forum_id => $forum_id, } )->delete;
    if ( scalar @poll_ids ) {
        $c->model('DBIC::PollOption')
            ->search( { poll_id => { 'IN', \@poll_ids }, } )->delete;
        $c->model('DBIC::PollResult')
            ->search( { poll_id => { 'IN', \@poll_ids }, } )->delete;
    }

    # comment and star
    if ( scalar @topic_ids ) {
        $c->model('DBIC::Comment')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
        $c->model('DBIC::Star')->search(
            {   object_type => 'topic',
                object_id   => { 'IN', \@topic_ids },
            }
        )->delete;
    }
    if ( scalar @poll_ids ) {
        $c->model('DBIC::Comment')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
        $c->model('DBIC::Star')->search(
            {   object_type => 'poll',
                object_id   => { 'IN', \@poll_ids },
            }
        )->delete;
    }

    # for upload
    $c->model('Upload')->remove_for_forum( $c, $forum_id );
}

sub merge_forums {
    my ( $self, $c, $info ) = @_;

    my $from_id = $info->{from_id} or return 0;
    my $to_id   = $info->{to_id}   or return 0;

    my $old_forum = $c->model('DBIC::Forum')->find( { forum_id => $from_id } );
    return unless ($old_forum);
    my $new_forum = $c->model('DBIC::Forum')->find( { forum_id => $to_id } );
    return unless ($new_forum);
    $c->model('DBIC::Forum')->search( { forum_id => $from_id, } )->delete;

    # update new
    my $total_topics  = $old_forum->total_topics;
    my $total_replies = $old_forum->total_replies;
    my $total_members = $old_forum->total_members;
    my @extra_cols;
    if ( $new_forum->policy eq 'private' ) {
        @extra_cols = ( 'total_members', \"total_members + $total_members" );
    }
    $c->model('DBIC::Forum')->search( { forum_id => $to_id, } )->update(
        {   total_topics  => \"total_topics  + $total_topics",
            total_replies => \"total_replies + $total_replies",
            @extra_cols,
        }
    );
    $c->model('Policy')->remove_user_role( $c, { field => $from_id, } );

    # topics
    $c->model('DBIC::Topic')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # FIXME!!!
    # need delete all topic_id cache object
    # $c->cache->delete("topic|topic_id=$topic_id");

    # polls
    $c->model('DBIC::Poll')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # comment and star
    $c->model('DBIC::Comment')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );

    # for upload
    $c->model('Upload')->change_for_forum( $c, $info );

    return 1;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
