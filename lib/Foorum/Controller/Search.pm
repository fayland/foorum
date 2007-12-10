package Foorum::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub default : Private {
    my ($self, $c) = @_;
    
    $c->stash->{template} = 'search/index.html';
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
