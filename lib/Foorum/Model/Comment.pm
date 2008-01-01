package Foorum::Model::Comment;

use strict;
use warnings;
use base 'Catalyst::Model';
use Foorum::Utils qw/get_page_from_url encodeHTML/;
use Foorum::Formatter qw/filter_format/;
use Foorum::ExternalUtils qw/theschwartz/;
use Data::Page;
use List::MoreUtils qw/uniq first_index/;
use Scalar::Util    qw/blessed/;

sub get_comments_by_object {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $page        = $info->{page} || get_page_from_url( $c->req->path );
    my $rows        = $info->{rows} || $c->config->{per_page}->{topic} || 10;

    my @comments = $self->get_all_comments_by_object( $c, $object_type, $object_id );

    if ( $object_type eq 'user_profile' ) {
        @comments = reverse(@comments);
    }

    # when url contains /comment_id=$comment_id/
    # we need show that page including $comment_id
    if ( scalar @comments > $rows and $c->req->path =~ /\/comment_id=(\d+)(\/|$)/ ) {
        my $comment_id = $1;
        my $first_index = first_index { $_->{comment_id} == $comment_id } @comments;
        $page = int( $first_index / $rows ) + 1 if ($first_index);
    }

    my $pager = Data::Page->new();
    $pager->current_page($page);
    $pager->entries_per_page($rows);
    $pager->total_entries( scalar @comments );

    @comments = splice( @comments, ( $page - 1 ) * $rows, $rows );

    @comments = $self->prepare_comments_for_view( $c, @comments );

    $c->stash->{comments}       = \@comments;
    $c->stash->{comments_pager} = $pager;
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
                = $c->model('FilterWord')->convert_offensive_word( $c, $rec->{title} );
            $rec->{text}
                = $c->model('FilterWord')->convert_offensive_word( $c, $rec->{text} );
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

    my $comment = $c->model('DBIC')->resultset('Comment')->find(
        {   comment_id => $comment_id,
        }
    );
    return unless ($comment);

    $comment = $comment->{_column_data};
    if ( $attrs->{with_text} ) {
        # filter format by Foorum::Filter
        $comment->{text} = $c->model('FilterWord')
            ->convert_offensive_word( $c, $comment->{text} );
        $comment->{text}
            = filter_format( $comment->{text},
            { format => $comment->{formatter} } );
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

    # we don't use [% | html %] now because of my bad memory in TT html
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

sub remove {
    my ( $self, $c, $comment ) = @_;

    if ( blessed $comment ) {
        $comment = $comment->{_column_data};
    }

    if ( $comment->{upload_id} ) {
        $c->model('Upload')->remove_file_by_upload_id( $c, $comment->{upload_id} );
    }
    $c->model('DBIC::Comment')->search( { comment_id => $comment->{comment_id} } )->delete;

    my $object_type = $comment->{object_type};
    my $object_id   = $comment->{object_id};
    my $cache_key   = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->remove($cache_key);
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
