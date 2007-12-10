package Foorum::Controller::My;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;

sub auto : Private {
    my ( $self, $c ) = @_;

    unless ( $c->user_exists ) {
        $c->res->redirect('/login');
        return 0;
    }
    return 1;
}

sub starred : Local {
    my ( $self, $c ) = @_;

    my $page = get_page_from_url( $c->req->path );

    my $rs = $c->model('DBIC::Star')->search(
        { user_id => $c->user->user_id, },
        {   order_by => \'time DESC',
            rows     => 20,
            page     => $page,
        }
    );

    my @objects = $rs->all;

    my @starred_items;
    foreach my $rec (@objects) {
        my $object = $c->model('Object')->get_object_by_type_id(
            $c,
            {   object_type => $rec->object_type,
                object_id   => $rec->object_id,
            }
        );
        next unless ($object);
        push @starred_items,
            {
            object_type => $rec->object_type,
            object_id   => $rec->object_id,
            object      => $object
            };
    }

    $c->stash(
        {   template      => 'my/starred.html',
            starred_items => \@starred_items,
            pager         => $rs->pager,
            url_prefix    => '/my/starred',
        }
    );
}

sub topics : Local {
    my ( $self, $c ) = @_;

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Topic')->search(
        {  author_id  => $c->user->user_id,
          'me.status' => { '!=', 'banned' }, },
        {   order_by => \'last_update_date DESC',
            prefetch => [ 'last_updator', 'forum' ],
            join     => [qw/forum/],
            rows     => 20,
            page     => $page,
        }
    );

    $c->stash(
        {   template    => 'site/recent.html',
            topics      => [ $rs->all ],
            pager       => $rs->pager,
            recent_type => 'my',
            url_prefix  => '/my/topics',
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
