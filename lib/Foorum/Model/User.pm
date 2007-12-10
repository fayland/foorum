package Foorum::Model::User;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;
use Object::Signature ();
use Scalar::Util      ();

# Usage:
# $c->model('User')->get($c, { user_id => ? } );
# $c->model('User')->get($c, { username => ? } );
# $c->model('User')->get($c, { email => ? } );
sub get {
    my ( $self, $c, $cond ) = @_;

    my $cache_key = 'user|' . Object::Signature::signature($cond);

    if ( $c->stash->{"__user_caches|$cache_key"} ) {    # avoid memcache get
        $c->log->debug('get user from stash');
        return $c->stash->{"__user_caches|$cache_key"};
    }

    my $cache_val = $c->cache->get($cache_key);

    if ($cache_val) {
        $c->stash->{"__user_caches|$cache_key"} = $cache_val;
        $c->log->debug( 'get user from cache: ' . Dumper( \$cond ) );
        return $cache_val;
    }

    $cache_val = get_user_from_db( $self, $c, $cond );
    return unless ($cache_val);

    $c->log->debug( 'set user to cache: ' . Dumper( \$cond ) );
    $c->cache->set( $cache_key, $cache_val, 7200 );    # two hours
    $c->stash->{"__user_caches|$cache_key"} = $cache_val;
    return $cache_val;
}

# Usage:
# $c->model('User')->get_multi($c, user_id => [1, 2, 3]  );
# $c->model('User')->get_multi($c, username => ['fayland', 'testman'] );
sub get_multi {
    my ( $self, $c, $key, $val ) = @_;

    my @mem_keys;
    my %val_map_key;
    foreach (@$val) {
        my $cache_key
            = 'user|' . Object::Signature::signature( { $key => $_ } );
        push @mem_keys, $cache_key;
        $val_map_key{$_} = $cache_key;
    }

    my $users = $c->cache->get_multi(@mem_keys);

    my %return_users;
    foreach my $v (@$val) {
        if ( exists $users->{ $val_map_key{$v} } ) {
            $return_users{$v} = $users->{ $val_map_key{$v} };
        } else {
            $return_users{$v} = get_user_from_db( $self, $c, { $key => $v } );
            next unless ( $return_users{$v} );
            $c->log->debug("set user to cache in multi: $key => $v");
            $c->cache->set( $val_map_key{$v}, $return_users{$v}, 7200 )
                ;    # two hours
        }
    }

    return \%return_users;
}

sub get_user_from_db {
    my ( $self, $c, $cond ) = @_;

    my $user = $c->model('DBIC')->resultset('User')->find($cond);
    return unless ($user);

    # user_details
    my $user_details = $c->model('DBIC')->resultset('UserDetails')
        ->find( { user_id => $user->user_id } );
    $user_details = $user_details->{_column_data} if ($user_details);

    # user role
    my @roles = $c->model('DBIC')->resultset('UserRole')
        ->search( { user_id => $user->user_id, } )->all;
    my $roles;
    foreach (@roles) {
        $roles->{ $_->field }->{ $_->role } = 1;
    }

    # user profile photo
    my $profile_photo = $c->model('DBIC')->resultset('UserProfilePhoto')->find( {
        user_id => $user->user_id,
    } );
    if ($profile_photo) {
        $profile_photo = $profile_photo->{_column_data};
        if ($profile_photo->{type} eq 'upload') {
             my $profile_photo_upload = $c->model('Upload')->get( $c, $profile_photo->{value} );
             $profile_photo->{upload} = $profile_photo_upload if ($profile_photo_upload);
        }
    }

    $user                  = $user->{_column_data};
    $user->{details}       = $user_details;
    $user->{roles}         = $roles;
    $user->{profile_photo} = $profile_photo;
    return $user;
}

sub delete_cache_by_user {
    my ( $self, $c, $user ) = @_;

    return unless ($user);

    my @ckeys;
    push @ckeys, 'user|'
        . Object::Signature::signature( { user_id => $user->{user_id} } );
    push @ckeys, 'user|'
        . Object::Signature::signature( { username => $user->{username} } );
    push @ckeys,
        'user|' . Object::Signature::signature( { email => $user->{email} } );

    foreach my $ckey (@ckeys) {
        $c->cache->delete($ckey);
        $c->stash->{"__user_caches|$ckey"} = undef;
    }

    return 1;
}

sub delete_cache_by_user_cond {
    my ( $self, $c, $cond ) = @_;

    my $user = $self->get( $c, $cond );
    $self->delete_cache_by_user( $c, $user );
}

# call this update will delete cache.
sub update {
    my ( $self, $c, $user, $update ) = @_;

    $self->delete_cache_by_user( $c, $user );
    $c->model('DBIC')->resultset('User')
        ->search( { user_id => $user->{user_id}, } )->update($update);
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
