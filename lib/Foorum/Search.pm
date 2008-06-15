package Foorum::Search;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;

use Foorum::Search::Sphinx;
use Foorum::Search::Database;

sub new {
    my $class = shift;
    my $self  = {@_};

    my $sphinx = new Foorum::Search::Sphinx;
    if ( $sphinx->can_search() ) {
        $self->{use_sphinx} = 1;
        $self->{sphinx}     = $sphinx;
    } else {
        $self->{use_db} = 1;
        $self->{db}     = new Foorum::Search::Database;
    }

    return bless $self => $class;
}

sub query {
    my ( $self, $type, $params ) = @_;

    if ( $self->{use_sphinx} ) {
        return $self->{sphinx}->query( $type, $params );
    } else {
        return $self->{db}->query( $type, $params );
    }
}

1;
__END__

=pod

=head1 NAME

Foorum::Search - search Foorum

=head1 SYNOPSIS

  use Foorum::Search;
  # TODO

=head1 DESCRIPTION

This module is mainly to design the interface of Foorum search regardless the backend (Sphinx or Database or others)

=head1 SEE ALSO

L<Foorum::Search::Database>, L<Foorum::Search::Sphinx>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
