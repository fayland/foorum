package Foorum::Model::Policy;

use strict;
use warnings;
use base 'Catalyst::Model';

sub fill_user_role {
    my ( $self, $c, $field ) = @_;

    my $roles = $c->user->{roles};
    $field ||= 'site';

    if ( $roles->{$field}->{user} ) {
        $roles->{is_member} = 1;
    }

    if ( $roles->{site}->{moderator} || $roles->{$field}->{moderator} ) {
        $roles->{is_member}    = 1;
        $roles->{is_moderator} = 1;
    }

    if ( $roles->{site}->{admin} || $roles->{$field}->{admin} ) {
        $roles->{is_member}    = 1;
        $roles->{is_moderator} = 1;
        $roles->{is_admin}     = 1;
    }

    if ( $roles->{$field}->{blocked} ) {
        $roles->{is_member}  = 0;
        $roles->{is_blocked} = 1;
    }

    if ( $roles->{$field}->{pending} ) {
        $roles->{is_member}  = 0;
        $roles->{is_pending} = 1;
    }

    if ( $roles->{$field}->{rejected} ) {
        $roles->{is_member}   = 0;
        $roles->{is_rejected} = 1;
    }

    $c->stash->{roles} = $roles;
    return $roles;
}

sub is_admin {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_admin};
}

sub is_moderator {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_moderator};
}

sub is_user {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_member};
}

sub is_pending {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_pending};
}

sub is_rejected {
    my ( $self, $c, $field ) = @_;

    &fill_user_role( $self, $c, $field ) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_rejected};
}

sub is_blocked {
    my ( $self, $c, $field ) = @_;

    &fill_user_role(@_) unless ( $c->stash->{roles} );

    return $c->stash->{roles}->{is_blocked};
}

sub get_forum_moderators {
    my ( $self, $c, $forum_id ) = @_;

    # for forum_id is an ARRAYREF: [1,2], we don't cache it because
    # when remove_user_role, we don't know how to clear all forum1's keys.

    my $mem_key;
    if ( $forum_id =~ /^\d+$/ ) {
        $mem_key = "policy|user_role|forum_id=$forum_id";
        my $mem_val = $c->cache->get($mem_key);
        return $mem_val if ($mem_val);
    }

    my @users = $c->model('DBIC')->resultset('UserForum')->search(
        {   status => [ 'admin', 'moderator' ],
            forum_id => $forum_id,
        }
    )->all;

    my $roles;
    foreach (@users) {
        my $user = $c->model('DBIC::User')->get( { user_id => $_->user_id, } );
        next unless ($user);
        if ( $_->status eq 'admin' ) {
            $roles->{ $_->forum_id }->{'admin'} = {    # for cache
                username => $user->{username},
                nickname => $user->{nickname}
            };
        } elsif ( $_->status eq 'moderator' ) {
            push @{ $roles->{ $_->forum_id }->{'moderator'} }, $user;
        }
    }

    $c->cache->set( $mem_key, $roles ) if ($mem_key);

    return $roles;
}

sub get_forum_admin {
    my ( $self, $c, $forum_id ) = @_;

    # get admin
    my $rs = $c->model('DBIC::UserForum')->search(
        {   forum_id => $forum_id,
            status  => 'admin',
        }
    )->first;
    return unless ($rs);
    my $user = $c->model('DBIC::User')->get( { user_id => $rs->user_id } );
    return $user;
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
