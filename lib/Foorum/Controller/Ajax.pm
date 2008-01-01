package Foorum::Controller::Ajax;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Formatter qw/filter_format/;

sub auto : Private {
    my ( $self, $c ) = @_;

    # no cache
    $c->res->header( 'Cache-Control' => 'no-cache, must-revalidate, max-age=0' );
    $c->res->header( 'Pragma'        => 'no-cache' );

    return 1;
}

=pod

=item validate_username

Ajax way to validate the username in Register progress.

=cut

sub validate_username : Local {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');

    my $ERROR = $c->model('Validation')->validate_username( $c, $username );
    return $c->res->body($ERROR) if ($ERROR);

    $c->res->body('OK');
}

sub star : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $object_type = $c->req->param('obj_type');
    my $object_id   = $c->req->param('obj_id');

    # validate
    $object_type =~ s/\W+//g;
    $object_id   =~ s/\D+//g;
    return $c->res->body('ERROR') unless ( $object_type and $object_id );

    # if we already has it, it's unstar, or else, it's star
    my $ret = $c->model('DBIC')->resultset('Star')->del_or_create(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        }
    );
    $c->res->body($ret);
}

sub share : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $object_type = $c->req->param('obj_type');
    my $object_id   = $c->req->param('obj_id');

    # validate
    $object_type =~ s/\W+//g;
    $object_id   =~ s/\D+//g;
    return $c->res->body('ERROR') unless ( $object_type and $object_id );

    # if we already has it, it's unstar, or else, it's star
    my $ret = $c->model('DBIC')->resultset('Share')->del_or_create(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        }
    );
    $c->res->body($ret);
}

sub preview : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $formatter = $c->req->param('formatter');
    my $text      = $c->req->param('text');

    return $c->res->body(' ') unless ( length($text) );

    $text = $c->model('FilterWord')->convert_offensive_word( $c, $text );
    $text = filter_format( $text, { format => $formatter } );

    $c->res->body($text);
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

