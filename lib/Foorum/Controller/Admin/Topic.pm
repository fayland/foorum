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
        url_prefix => '/admin/topic',
        url_postfix => $banned ? '?banned=1' : undef,
    } );
}

sub batch_ban : Local {
    my ( $self, $c ) = @_;

    my $unban     = $c->req->param('unban') || 0;
    my @topic_ids = $c->req->param('topic_id');
    if ( scalar @topic_ids == 1 ) {
        @topic_ids = split(/\,\s*/, $topic_ids[0]);
    }

    foreach my $topic_id ( @topic_ids ) {
        next if $topic_id !~ /^\d+$/;
        my $status = $unban ? 'healthy' : 'banned';
        $c->model('DBIC::Topic')
            ->update_topic( $topic_id, { status => $status } );
    }

    $c->forward(
        '/print_message',
        [   {   msg => $unban ? 'Batch unBan OK' : 'Batch Ban OK',
                url => $unban ? '/admin/topic?banned=1' : '/admin/topic',
            }
        ]
    );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
