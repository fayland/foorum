package Foorum::Model::PluginHack;

use strict;
use warnings;
use base 'Catalyst::Model';

sub get {
    my ($self, $c, $user_info) = @_;
    
    my $where;
    if (exists $user_info->{user_id}) {
        $where = { user_id => $user_info->{user_id} };
    } elsif (exists $user_info->{username}) {
        $where = { username => $user_info->{username} };
    } else { return; }

    my $user = $c->model('User')->get( $c, $where );
    return $user;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
