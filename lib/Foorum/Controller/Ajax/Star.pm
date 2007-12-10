package Foorum::Controller::Ajax::Star;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;

sub default : Private {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $object_type = $c->req->param('obj_type');
    my $object_id   = $c->req->param('obj_id');

    # validate
    $object_type =~ s/\W+//g;
    $object_id   =~ s/\D+//g;
    return $c->res->body('ERROR') unless ( $object_type and $object_id );

    # if we already has it, it's unstar, or else, it's star
    my $count = $c->model('DBIC::Star')->count(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        }
    );
    if ($count) {

        # unstar
        $c->model('DBIC::Star')->search(
            {   user_id     => $c->user->user_id,
                object_type => $object_type,
                object_id   => $object_id,
            }
        )->delete;
        $c->res->body('0');
    } else {

        # star
        $c->model('DBIC::Star')->create(
            {   user_id     => $c->user->user_id,
                object_type => $object_type,
                object_id   => $object_id,
                time        => time(),
            }
        );
        $c->res->body('1');
    }
}

# override Root.pm
sub end : Private {
    my ( $self, $c ) = @_;

}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
