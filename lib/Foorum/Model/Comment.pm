package Foorum::Model::Comment;

use strict;
use warnings;
use base 'Catalyst::Model';
use Foorum::Utils qw/get_page_from_url encodeHTML/;
use Foorum::Formatter qw/filter_format/;
use Data::Page;
use Data::Dumper;

sub get_comments_by_object {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $page        = $info->{page} || get_page_from_url( $c->req->path );

    my $cache_key   = "comment|object_type=$object_type|object_id=$object_id";
    my $cache_value = $c->cache->get($cache_key);

    my @comments;
    if ($cache_value) {
        $c->log->debug('Cache: get comments');
        @comments = @{ $cache_value->{comments} };
    } else {
        my $it = $c->model('DBIC')->resultset('Comment')->search(
            {   object_type => $object_type,
                object_id   => $object_id,
            },
            {   order_by => 'post_on',
                prefetch => [ 'upload' ],
            }
        );

        while ( my $rec = $it->next ) {
            my $upload = ( $rec->upload ) ? $rec->upload : undef;
            $rec = $rec->{_column_data};    # for memcached using
            $rec->{upload} = $upload->{_column_data} if ($upload);

            # filter format by Foorum::Filter
            $rec->{title} = $c->model('FilterWord')
                ->convert_offensive_word( $c, $rec->{title} );
            $rec->{text} = $c->model('FilterWord')
                ->convert_offensive_word( $c, $rec->{text} );
            $rec->{text} = filter_format( $rec->{text},
                { format => $rec->{formatter} } );

            push @comments, $rec;
        }
        $cache_value = { comments => \@comments };
        $c->cache->set( $cache_key, $cache_value, 3600 );    # 1 hour
        $c->log->debug('Cache: set comments');
    }

    my $rows = $c->config->{per_page}->{topic} || 10;
    my $pager = Data::Page->new();
    $pager->current_page($page);
    $pager->entries_per_page($rows);
    $pager->total_entries( scalar @comments );

    @comments = splice( @comments, ( $page - 1 ) * $rows, $rows );

    my @all_user_ids; my %unique_user_ids;
    foreach (@comments) {
        next if ($unique_user_ids{$_->{author_id}});
        push @all_user_ids, $_->{author_id};
        $unique_user_ids{$_->{author_id}} = 1;
    }
    if (scalar @all_user_ids) {
        my $authors = $c->model('User')->get_multi($c, 'user_id', \@all_user_ids);
        foreach (@comments) {
            $_->{author} = $authors->{$_->{author_id}};
        }
    }

    $c->stash->{comments}       = \@comments;
    $c->stash->{comments_pager} = $pager;
}

sub get {
    my ( $self, $c, $comment_id, $attrs ) = @_;

    my @extra_where;
    push @extra_where, ( object_type => $attrs->{object_type} )
        if ( $attrs->{object_type} );
    push @extra_where, ( object_id => $attrs->{object_id} )
        if ( $attrs->{object_id} );

    my $comment = $c->model('DBIC')->resultset('Comment')->search(
        {   comment_id => $comment_id,
            @extra_where,
        },
    )->first;

    # print error if the comment is non-exist
    $c->detach( '/print_error', ['Non-existent comment'] ) unless ($comment);

    if ( $attrs->{with_text} ) {

        # filter format by Foorum::Filter
        $comment->{_column_data}->{text} = $c->model('FilterWord')
            ->convert_offensive_word( $c, $comment->{_column_data}->{text} );
        $comment->{_column_data}->{text} = filter_format(
            $comment->{_column_data}->{text},
            { format => $comment->formatter }
        );
    }
    if ( $attrs->{with_author} ) {
        $comment->{author} = $c->model('User')->get($c, { user_id => $comment->author_id });
    }

    $c->stash->{comment} = $comment;

    return $comment;
}

sub create {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $forum_id    = $info->{forum_id} || 0;
    my $reply_to    = $info->{reply_to} || 0;

    # we prefer [% | html %] now because of my bad memory in TT html
    my $title = $c->req->param('title');
    $title = encodeHTML($title);

    my $comment = $c->model('DBIC')->resultset('Comment')->create(
        {   object_type => $object_type,
            object_id   => $object_id,
            author_id   => $c->user->user_id,
            title       => $title,
            text        => $c->req->param('text') || '',
            formatter   => 'ubb',
            post_on     => \'NOW()',
            post_ip     => $c->req->address,
            reply_to    => $reply_to,
            forum_id    => $forum_id,
            upload_id   => $info->{upload_id} || 0,
        }
    );

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->delete($cache_key);

    return $comment;
}

sub remove {
    my ( $self, $c, $comment ) = @_;

    if ( $comment->upload_id ) {
        $c->model('Upload')
            ->remove_file_by_upload_id( $c, $comment->upload_id );
    }
    $c->model('DBIC::Comment')
        ->search( { comment_id => $comment->comment_id } )->delete;

    my $object_type = $comment->object_type;
    my $object_id   = $comment->object_id;
    my $cache_key   = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->delete($cache_key);
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
