package Foorum::Controller::Admin::Topic;

use strict;
use warnings;
our $VERSION = '1.000005';
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;

sub auto : Private {
    my ( $self, $c ) = @_;

    # only administrator is allowed. site moderator is not allowed here
    unless ( $c->model('Policy')->is_admin( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    my $banned = $c->req->param('banned') || 0;
    my $stcond = $banned ? 'banned' : { '!=', 'banned' };
    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Topic')->search(
        {   'me.status'    => $stcond,
        },
        {   order_by => 'topic_id desc',
            rows     => 20,
            page     => $page,
        }
    );
    $c->stash( {
        template   => 'admin/topic/index.html',
        topics     => [ $rs->all ],
        pager      => $rs->pager,
    } );
}

sub batch : Local {
    my ( $self, $c ) = @_;

    my $do        = $c->req->param('do');
    my @topic_ids = $c->req->param('topic_id');
    if ( scalar @topic_ids == 1 ) {
        @topic_ids = split(/\,\s*/, $topic_ids[0]);
    }

    foreach my $topic_id ( @topic_ids ) {
        next if $topic_id !~ /^\d+$/;
        if ( $do eq 'ban' or $do eq 'unban' ) {
            my $status = $do eq 'unban' ? 'healthy' : 'banned';
            $c->model('DBIC::Topic')
                ->update_topic( $topic_id, { status => $status } );
        } elsif ( $do eq 'delete' ) {
            $c->model('DBIC::Topic')->remove(
                $topic_id,
                {   log_text    => 'Deleted by Admin',
                    operator_id => $c->user->user_id
                }
            );
        }
    }

    $c->res->redirect('/admin/topic?info=1');
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
