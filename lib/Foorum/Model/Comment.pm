package Foorum::Model::Comment;

use strict;
use warnings;
use base 'Catalyst::Model';
use Foorum::Utils qw/get_page_from_url encodeHTML/;
use Foorum::Formatter qw/filter_format/;
use Foorum::ExternalUtils qw/theschwartz/;
use Data::Page;
use List::MoreUtils qw/uniq first_index part/;
use List::Util qw/first/;
use Scalar::Util qw/blessed/;

sub get_comments_by_object {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $page        = $info->{page} || get_page_from_url( $c->req->path );
    my $rows        = $info->{rows} || $c->config->{per_page}->{topic} || 10;

    # 'thread' or 'flat'
    my $view_mode = $info->{view_mode};
    ($view_mode) = ( $c->req->path =~ /\/view_mode=(thread|flat)(\/|$)/ );

    #$view_mode ||= ($object_type eq 'topic') ? 'thread' : 'flat';
    $view_mode ||= 'thread';    # XXX? Temp

    my @comments = $self->get_all_comments_by_object( $c, $object_type, $object_id );

    my $pager = Data::Page->new();
    $pager->current_page($page);
    $pager->entries_per_page($rows);

    if ( $view_mode eq 'flat' ) {

        # when url contains /comment_id=$comment_id/
        # we need show that page including $comment_id
        if ( scalar @comments > $rows and $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ ) {
            my $comment_id = $1;
            my $first_index = first_index { $_->{comment_id} == $comment_id } @comments;
            $page = int( $first_index / $rows ) + 1 if ($first_index);
            $pager->current_page($page);
        }
        $pager->total_entries( scalar @comments );
        if ( $object_type eq 'user_profile' ) {
            @comments = reverse(@comments);
        }
        @comments = splice( @comments, ( $page - 1 ) * $rows, $rows );
    } else {    # thread mode
                # top_comments: the top level comments
        my ( @top_comments, @result_comments );

        # for topic. reply_to == 0 means the topic comments
        #            reply_to == topic.comments[0].comment_id means top level.
        if ( $object_type eq 'topic' ) {
            ( my $top_comments ) = part {
                ( $_->{reply_to} == 0 or $_->{reply_to} == $comments[0]->{comment_id} )
                    ? 0
                    : 1;
            }
            @comments;
            @top_comments = @$top_comments;
        } else {
            ( my $top_comments ) = part {
                $_->{reply_to} == 0 ? 0 : 1;
            }
            @comments;
            $top_comments ||= [];
            @top_comments = @$top_comments;
        }

        # when url contains /comment_id=$comment_id/
        # we need show that page including $comment_id
        if ( scalar @top_comments > $rows
            and $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ ) {
            my $comment_id = $1;

            # need to find out the top comment's comment_id
            my $top_comment = first { $_->{comment_id} == $comment_id } @comments;
            while (1) {
                my $reply_to = $top_comment->{reply_to};
                $comment_id = $top_comment->{comment_id};
                last if ( $reply_to == 0 );
                last
                    if ($object_type eq 'topic'
                    and $reply_to == $comments[0]->{comment_id} );
                $top_comment = first { $_->{comment_id} == $reply_to } @comments;
            }
            my $first_index
                = first_index { $_->{comment_id} == $comment_id } @top_comments;
            $page = int( $first_index / $rows ) + 1 if ($first_index);
            $pager->current_page($page);
        }

        # paged by top_comments
        $pager->total_entries( scalar @top_comments );
        if ( $object_type eq 'user_profile' ) {
            @top_comments = reverse(@top_comments);
        }
        @top_comments = splice( @top_comments, ( $page - 1 ) * $rows, $rows );

        foreach (@top_comments) {
            $_->{level} = 0;
            push @result_comments, $_;
            next
                if ($object_type eq 'topic'
                and $_->{comment_id} == $comments[0]->{comment_id} );

            # get children, 10 lines below
            $self->get_children_comments( $_->{comment_id}, 1, \@comments,
                \@result_comments );
        }
        @comments = @result_comments;
    }

    @comments = $self->prepare_comments_for_view( $c, @comments );

    $c->stash->{comments}       = \@comments;
    $c->stash->{comments_pager} = $pager;
}

sub get_children_comments {
    my ( $self, $reply_to, $level, $comments, $result_comments ) = @_;

    my ( $tmp_comments, $left_comments ) = part {
        $_->{reply_to} == $reply_to ? 0 : 1;
    }
    @$comments;
    return unless ($tmp_comments);

    foreach (@$tmp_comments) {
        $_->{level} = $level;
        push @$result_comments, $_;
        $self->get_children_comments( $_->{comment_id}, $level + 1, $left_comments,
            $result_comments );
    }
}

sub get_all_comments_by_object {
    my ( $self, $c, $object_type, $object_id ) = @_;

    my $cache_key   = "comment|object_type=$object_type|object_id=$object_id";
    my $cache_value = $c->cache->get($cache_key);

    my @comments;
    if ($cache_value) {
        $c->log->debug("Cache: get comments $cache_key");
        @comments = @{ $cache_value->{comments} };
    } else {
        my $it = $c->model('DBIC')->resultset('Comment')->search(
            {   object_type => $object_type,
                object_id   => $object_id,
            },
            {   order_by => 'post_on',
                prefetch => ['upload'],
            }
        );

        while ( my $rec = $it->next ) {
            my $upload = ( $rec->upload ) ? $rec->upload : undef;
            $rec = $rec->{_column_data};    # for cache using
            $rec->{upload} = $upload->{_column_data} if ($upload);

            # filter format by Foorum::Filter
            $rec->{title}
                = $c->model('DBIC::FilterWord')->convert_offensive_word( $rec->{title} );
            $rec->{text}
                = $c->model('DBIC::FilterWord')->convert_offensive_word( $rec->{text} );
            $rec->{text} = filter_format( $rec->{text}, { format => $rec->{formatter} } );

            push @comments, $rec;
        }
        $cache_value = { comments => \@comments };
        $c->cache->set( $cache_key, $cache_value, 3600 );    # 1 hour
        $c->log->debug("Cache: set comments $cache_key");
    }

    return wantarray ? @comments : \@comments;
}

# add author and others
sub prepare_comments_for_view {
    my ( $self, $c, @comments ) = @_;

    my @all_user_ids;
    foreach (@comments) {
        push @all_user_ids, $_->{author_id};
    }
    if ( scalar @all_user_ids ) {
        @all_user_ids = uniq @all_user_ids;
        my $authors = $c->model('User')->get_multi( $c, 'user_id', \@all_user_ids );
        foreach (@comments) {
            $_->{author} = $authors->{ $_->{author_id} };
        }
    }

    return wantarray ? @comments : \@comments;
}

sub get {
    my ( $self, $c, $comment_id, $attrs ) = @_;

    my $comment
        = $c->model('DBIC')->resultset('Comment')->find( { comment_id => $comment_id, } );
    return unless ($comment);

    $comment = $comment->{_column_data};
    if ( $attrs->{with_text} ) {

        # filter format by Foorum::Filter
        $comment->{text}
            = $c->model('DBIC::FilterWord')->convert_offensive_word( $comment->{text} );
        $comment->{text}
            = filter_format( $comment->{text}, { format => $comment->{formatter} } );
    }

    return $comment;
}

sub create {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $forum_id    = $info->{forum_id} || 0;
    my $reply_to    = $info->{reply_to} || 0;
    my $formatter   = $info->{formatter} || 'ubb';
    my $title       = $info->{title} || $c->req->param('title');
    my $text        = $info->{text} || $c->req->param('text') || '';

    # we don't use [% | html %] now because there is too many title around in TT
    $title = encodeHTML($title);

    my $comment = $c->model('DBIC')->resultset('Comment')->create(
        {   object_type => $object_type,
            object_id   => $object_id,
            author_id   => $c->user->user_id,
            title       => $title,
            text        => $text,
            formatter   => $formatter,
            post_on     => \'NOW()',                  #'
            post_ip     => $c->req->address,
            reply_to    => $reply_to,
            forum_id    => $forum_id,
            upload_id   => $info->{upload_id} || 0,
        }
    );

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->remove($cache_key);

    # Email Sent
    if ( $object_type eq 'user_profile' ) {
        my $rept = $c->model('User')->get( $c, { user_id => $object_id } );

        # Send Notification Email
        $c->model('Email')->create(
            $c,
            {   template => 'new_comment',
                to       => $rept->{email},
                stash    => {
                    rept    => $rept,
                    from    => $c->user,
                    comment => $comment,
                }
            }
        );
    } else {

        # Send Update Notification for Starred Item
        my $client = theschwartz();
        $client->insert(
            'Foorum::TheSchwartz::Worker::SendStarredNofication',
            [ $object_type, $object_id, $c->user->{user_id} ]
        );
    }

    return $comment;
}

sub remove_by_object {
    my ( $self, $c, $object_type, $object_id ) = @_;

    my $comment_rs = $c->model('DBIC::Comment')->search(
        {   object_type => $object_type,
            object_id   => $object_id,
        }
    );
    my $delete_counts = 0;
    while ( my $comment = $comment_rs->next ) {
        $self->remove_one_item( $c, $comment );
        $delete_counts++;
    }

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->remove($cache_key);

    return $delete_counts;
}

sub remove_children {
    my ( $self, $c, $comment ) = @_;

    if ( blessed $comment ) {
        $comment = $comment->{_column_data};
    }

    my $comment_id  = $comment->{comment_id};
    my $object_type = $comment->{object_type};
    my $object_id   = $comment->{object_id};

    my @comments = $self->get_all_comments_by_object( $c, $object_type, $object_id );
    my @result_comments;
    $self->get_children_comments( $comment_id, 1, \@comments, \@result_comments );

    my $delete_counts = 1;
    $self->remove_one_item( $c, $comment );
    foreach (@result_comments) {
        $self->remove_one_item( $c, $_ );
        $delete_counts++;
    }

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->remove($cache_key);

    return $delete_counts;
}

sub remove_one_item {
    my ( $self, $c, $comment ) = @_;

    if ( blessed $comment ) {
        $comment = $comment->{_column_data};
    }

    if ( $comment->{upload_id} ) {
        $c->model('Upload')->remove_file_by_upload_id( $c, $comment->{upload_id} );
    }
    $c->model('DBIC::Comment')->search( { comment_id => $comment->{comment_id} } )
        ->delete;

    return 1;
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
