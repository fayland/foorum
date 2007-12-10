package Foorum::Controller::Admin::Log;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;

sub error_log : Local {
    my ( $self, $c ) = @_;

    my $level = $c->req->param('level');
    my @extra_cols;
    if ( grep { $level eq $_ } ( 'info', 'debug', 'warn', 'error', 'fatal' ) )
    {
        push @extra_cols, ( 'level', $level );
        $c->stash->{has_level}   = 1;
        $c->stash->{url_postfix} = '?level=' . $level;
    }
    if ( my $text = $c->req->param('text') ) {
        push @extra_cols, ( 'text', { LIKE => "%$text%" } );
        $c->stash->{url_postfix} .= ( $c->stash->{url_postfix} ) ? '&' : '?';
        $c->stash->{url_postfix} .= 'text=' . $text;
    }

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC')->resultset('LogError')->search(
        {@extra_cols},
        {   rows     => 20,
            page     => $page,
            order_by => 'error_id DESC',
        }
    );
    my $pager  = $rs->pager;
    my @errors = $rs->all;

    $c->stash(
        {   template   => 'admin/log/error_log.html',
            errors     => \@errors,
            pager      => $pager,
            url_prefix => '/admin/log/error_log',
        }
    );
}

sub path_log : Local {
    my ( $self, $c ) = @_;

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC')->resultset('LogPath')->search(
        undef,
        {   rows     => 20,
            page     => $page,
            order_by => 'path_id DESC',
        }
    );
    my $pager = $rs->pager;
    my @paths = $rs->all;

    $c->stash(
        {   template   => 'admin/log/path_log.html',
            paths      => \@paths,
            pager      => $pager,
            url_prefix => '/admin/log/path_log',
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
