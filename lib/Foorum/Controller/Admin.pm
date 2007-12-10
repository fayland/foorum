package Foorum::Controller::Admin;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub auto : Private {
    my ( $self, $c ) = @_;

    unless ( $c->user_exists ) {
        $c->res->redirect('/login');
        return 0;
    }

    # we have admin or moderator for 'site' field
    unless ( $c->model('Policy')->is_moderator( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }

    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'admin/index.html';
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
