package Foorum::Model::UserAuth;

use strict;
use warnings;
use base 'Catalyst::Model';

sub auth {
    my ($self, $c, $userinfo) = @_;
    
    my $where;
    if (exists $userinfo->{user_id}) {
        $where = { user_id => $userinfo->{user_id} };
    } elsif (exists $userinfo->{username}) {
        $where = { username => $userinfo->{username} };
    } elsif (exists $userinfo->{email}) {
        $where = { email => $userinfo->{email} };
    } else { return; }

    my $user = $c->model('User')->get( $c, $where );
    return $user;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
