package Foorum::Model::Online;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub get_data {
    my ( $self, $c, $forum_code, $attr ) = @_;

    $attr->{page}     = 1         unless ( $attr->{page} );
    $attr->{order_by} = 'expires' unless ( $attr->{order_by} );

    my @extra_cols;
    if ($forum_code) {
        @extra_cols = (
            -or => [
                'path' => { 'like', "forum/$forum_code/%" },
                'path' => { 'like', "forum/$forum_code" },
            ]
        );
    }

    # get the last 15 minites' data
    # 15 * 60 = 900
    my $last_15_min = time() + $c->config->{session}->{expires} - 900;
    my $rs          = $c->model('DBIC::Session')->search(
        {   expires => { '>', $last_15_min },
            @extra_cols,
        },
        {   order_by => $attr->{order_by},
            rows     => 20,
            page     => $attr->{page},
        }
    );
    my @session = $rs->all;

    my @results = &_handler_session( $self, $c, @session );

    return wantarray ? ( \@results, $rs->pager ) : \@results;
}

sub whos_view_this_page {
    my ( $self, $c ) = @_;

    # get the last 15 minites' data
    # 15 * 60 = 900
    my $last_15_min = time() + $c->config->{session}->{expires} - 900;
    my @session     = $c->model('DBIC::Session')->search(
        {   expires => { '>', $last_15_min },
            path    => $c->req->path,
        },
        {   order_by => 'expires',
            rows     => 20,
            page     => 1,
        }
    )->all;

    #use Data::Dumper;
    #$c->log->debug(Dumper(\@session));

    my @results = &_handler_session( $self, $c, @session );

    #$c->log->debug(Dumper(\@results));

    return wantarray ? @results : \@results;
}

sub _handler_session {
    my ( $self, $c, @session ) = @_;

    my $has_me = 0;    # damn it, we query it *before* the path is updated.
    my @results;
    foreach my $session (@session) {
        my $data        = $c->get_session_data( $session->id );
        my $refer       = $session->path;
        my $visit_time  = $data->{__created};
        my $active_time = $data->{__updated};
        my $IP          = $data->{__address};
        my $user;
        if ( not $has_me and $session->id eq 'session:' . $c->sessionid ) {
            $has_me = 1;
        }
        if ( $session->user_id ) {
            if ( $c->user_exists and $session->user_id == $c->user->user_id )
            {
                $user  = $c->user;
                $refer = $c->req->path;
            } else {
                $user = $c->model('User')
                    ->get( $c, { user_id => $session->user_id } );
            }
        }
        push @results,
            {
            user        => $user,
            refer       => $refer,
            visit_time  => $visit_time,
            active_time => $active_time,
            IP          => $IP
            };
    }

    # add $c->user for whos_view_this_page
    unless ($has_me) {
        push @results,
            {
            user => $c->user || '',
            refer       => $c->req->path,
            visit_time  => $c->session->{__created},
            active_time => $c->session->{__updated},
            IP          => $c->session->{__address},
            };
    }

    return wantarray ? @results : \@results;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
