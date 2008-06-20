package Foorum::Controller::Settings;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';

sub default : Private {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'settings/index.html';
    if ( $c->req->method ne 'POST' ) {

        # for fullfil
        $c->stash->{settings} = $c->model('DBIC::User')->get_user_settings( $c->user );
        return;
    }

    # for submit

    my $send_starred_notification = $c->req->param('send_starred_notification');
    $send_starred_notification = 'Y' unless ( $send_starred_notification eq 'N' );
    my $show_email_public = $c->req->param('show_email_public');
    $show_email_public = 'Y' unless ( $show_email_public eq 'N' );

    # remove old data from db
    $c->model('DBIC')->resultset('UserSettings')->search(
        {   user_id => $c->user->{user_id},
            type    => { 'IN', [ 'send_starred_notification', 'show_email_public' ] },
        }
    )->delete;

    # insert new data
    if ( $send_starred_notification eq 'N' ) {    # don't store 'Y' because it's default
        $c->model('DBIC')->resultset('UserSettings')->create(
            {   user_id => $c->user->{user_id},
                type    => 'send_starred_notification',
                value   => 'N',
            }
        );
    }
    if ( $show_email_public eq 'N' ) {
        $c->model('DBIC')->resultset('UserSettings')->create(
            {   user_id => $c->user->{user_id},
                type    => 'show_email_public',
                value   => 'N',
            }
        );
    }

    # delete cache
    $c->cache->remove( 'user|user_settings|user_id=' . $c->user->{user_id} );
    $c->stash->{thanks} = 1;
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
