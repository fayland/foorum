package Foorum::ResultSet::SecurityCode;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class::ResultSet';

use Foorum::Utils qw/generate_random_word/;
use vars qw/%types/;

%types = ( forget_password => 1, );

sub get {
    my ( $self, $type, $user_id ) = @_;

    $type = $types{$type} if ( exists $types{$type} );

    my $rs = $self->search(
        {   type    => $type,
            user_id => $user_id
        }
    )->first;
    return unless ($rs);

    return $rs->code;
}

sub get_or_create {
    my ( $self, $type, $user_id ) = @_;

    my $code = $self->get( $type, $user_id );
    return $code if ( $code and length($code) );

    $type = $types{$type} if ( exists $types{$type} );
    return unless ($type);
    $code = &generate_random_word(12);

    $self->create(
        {   type    => $type,
            user_id => $user_id,
            code    => $code,
            time    => time()
        }
    );

    return $code;
}

sub remove {
    my ( $self, $type, $user_id ) = @_;

    $type = $types{$type} if ( exists $types{$type} );

    $self->search(
        {   type    => $type,
            user_id => $user_id
        }
    )->delete;
}

1;
__END__

