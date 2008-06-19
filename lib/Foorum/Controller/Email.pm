package Foorum::Controller::Email;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';

sub view : Local {
    my ( $self, $c, $uuid ) = @_;

    unless ($uuid and length($uuid) == 36) {
        return $c->detach('/print_error', [ 'ERROR_WRONG_VISIT' ] );
    }
    
    my $email = $c->model('DBIC')->resultset('ScheduledEmail')->search( {
        uuid => $uuid
    } )->first;
    
    unless ($email) {
        return $c->detach('/print_error', [ 'ERROR_WRONG_VISIT' ] );
    }

    $c->stash( {
        email => $email,
        template => 'email/view.html',
    } );
}

1;
__END__
