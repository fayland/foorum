package Foorum::Model::Policy;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

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

    my @users = $c->model('DBIC')->resultset('UserRole')->search(
        {   role  => [ 'admin', 'moderator' ],
            field => $forum_id,
        }
    )->all;

    my $roles;
    foreach (@users) {
        my $user = $c->model('User')->get( $c, { user_id => $_->user_id, } );
        next unless ($user);
        if ( $_->role eq 'admin' ) {
            $roles->{ $_->field }->{'admin'} = {    # for cache
                username => $user->{username},
                nickname => $user->{nickname}
            };
        } elsif ( $_->role eq 'moderator' ) {
            push @{ $roles->{ $_->field }->{'moderator'} }, $user;
        }
    }

    $c->cache->set( $mem_key, $roles ) if ($mem_key);

    return $roles;
}

sub get_forum_admin {
    my ( $self, $c, $forum_id ) = @_;

    # get admin
    my $rs = $c->model('DBIC::UserRole')->find(
        {   field => $forum_id,
            role  => 'admin',
        }
    );
    return unless ($rs);
    my $user = $c->model('User')->get( $c, { user_id => $rs->user_id } );
    return $user;
}

sub create_user_role {
    my ( $self, $c, $info ) = @_;

    $c->model('DBIC::UserRole')->create(
        {   user_id => $info->{user_id},
            field   => $info->{field},
            role    => $info->{role},
        }
    );

    clear_cached_policy( $self, $c, $info );
}

sub remove_user_role {
    my ( $self, $c, $info ) = @_;

    my @wheres;
    push @wheres, ( user_id => $info->{user_id} ) if ( $info->{user_id} );
    push @wheres, ( field   => $info->{field} )   if ( $info->{field} );
    push @wheres, ( role    => $info->{role} )    if ( $info->{role} );

    return unless ( scalar @wheres );

    $c->model('DBIC::UserRole')->search( { @wheres, } )->delete;

    clear_cached_policy( $self, $c, $info );
}

sub clear_cached_policy {
    my ( $self, $c, $info ) = @_;

    if ( $info->{user_id} ) {
        # clear user cache too
        $c->model('User')
            ->delete_cache_by_user_cond( $c,
            { user_id => $info->{user_id} } );
    }

    # field_id != 'site'
    if ($info->{field} =~ /^\d+$/
        and (  not $info->{role}
            or $info->{role} eq 'admin'
            or $info->{role} eq 'moderator' )
        )
    {
        $info->{forum_id} = $info->{field};
    }

    if ( $info->{forum_id} ) {
        $c->cache->delete("policy|user_role|forum_id=$info->{forum_id}");
    }

}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
