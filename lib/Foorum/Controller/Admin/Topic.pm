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

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Topic')->search(
        {   'me.status'    => { '!=', 'banned' },
        },
        {   order_by => 'topic_id desc',
            rows     => 20,
            page     => $page,
        }
    );
    $c->stash( {
        template   => 'admin/topic/index.html',
        topics     => [ $rs->all ],
        pager      => [ $rs->pager ],
        url_prefix => '/admin/topic'
    } );
}

sub batch_ban : Local {
    my ( $self, $c ) = @_;

    my @topic_ids = $c->req->param('topic_id');
    if ( scalar @topic_ids == 1 ) {
        @topic_ids = split(/\,\s*/, $topic_ids[0]);
    }

    foreach my $topic_id ( @topic_ids ) {
        next if $topic_id !~ /^\d+$/;
        $c->model('DBIC::Topic')
            ->update_topic( $topic_id, { status => 'banned' } );
    }

    $c->forward(
        '/print_message',
        [   {   msg => 'Batch Ban OK',
                url => '/admin/topic',
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
