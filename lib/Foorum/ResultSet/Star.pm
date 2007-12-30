package Foorum::ResultSet::Star;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub del_or_create {
    my ( $self, $cond ) = @_;

    my $count = $self->count($cond);
    if ($count) {
        $self->search($cond)->delete;
        return 0;
    } else {
        $cond->{time} = time();
        $self->create($cond);
        return 1;
    }
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
