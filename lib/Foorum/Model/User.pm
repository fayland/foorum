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
        my $cache_key = 'user|' . Object::Signature::signature( { $key => $_ } );
        push @mem_keys, $cache_key;
        $val_map_key{$_} = $cache_key;
    }

    my $cache = $c->default_cache_backend;
    my $users;
    if ( $cache->can('get_multi') ) {    # for Cache::Memcached
        $users = $cache->get_multi(@mem_keys);
    } else {
        foreach (@mem_keys) {
            $users->{$_} = $c->cache->get($_);
        }
    }

    my %return_users;
    foreach my $v (@$val) {
        if ( $users->{ $val_map_key{$v} } ) {
            $return_users{$v} = $users->{ $val_map_key{$v} };
        } else {
            $return_users{$v} = get_user_from_db( $self, $c, { $key => $v } );
            next unless ( $return_users{$v} );
            $c->log->debug("set user to cache in multi: $key => $v");
            $c->cache->set( $val_map_key{$v}, $return_users{$v}, 7200 );    # two hours
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
    my $profile_photo = $c->model('DBIC')->resultset('UserProfilePhoto')
        ->find( { user_id => $user->user_id, } );
    if ($profile_photo) {
        $profile_photo = $profile_photo->{_column_data};
        if ( $profile_photo->{type} eq 'upload' ) {
            my $profile_photo_upload
                = $c->model('Upload')->get( $c, $profile_photo->{value} );
            $profile_photo->{upload} = $profile_photo_upload
                if ($profile_photo_upload);
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
    push @ckeys,
        'user|' . Object::Signature::signature( { user_id => $user->{user_id} } );
    push @ckeys,
        'user|' . Object::Signature::signature( { username => $user->{username} } );
    push @ckeys, 'user|' . Object::Signature::signature( { email => $user->{email} } );

    foreach my $ckey (@ckeys) {
        $c->cache->remove($ckey);
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
    $c->model('DBIC')->resultset('User')->search( { user_id => $user->{user_id}, } )
        ->update($update);
}

# get user_settings
# we don't merge it into sub get_user_from_db is because it's not used so frequently
sub get_user_settings {
    my ( $self, $c, $user ) = @_;

    # this cachekey would be delete from Controller/Settings.pm
    my $cachekey = 'user|user_settings|user_id=' . $user->{user_id};
    my $cacheval = $c->cache->get($cachekey);

    if ($cacheval) {
        $cacheval = $cacheval->{val};
    } else {
        my $settings_rs = $c->model('DBIC')->resultset('UserSettings')
            ->search( { user_id => $user->{user_id} } );
        $cacheval = {};
        while ( my $rs = $settings_rs->next ) {
            $cacheval->{ $rs->type } = $rs->value;
        }
        $c->cache->set( $cachekey, { val => $cacheval, 1 => } );    # for empty $cacheval
    }

    # if not stored in db, we use default value;
    my $default = {
        'send_starred_notification' => 'Y',
        'show_email_public'         => 'Y',
    };
    my $ret = { %$default, %$cacheval };                            # merge
    return $ret;
}

1;
__END__

=pod

=head1 NAME

Foorum::Model::User - User object

=head1 FUNC

=over 4

=item get

  $c->model('User')->get($c, { user_id => ? } );
  $c->model('User')->get($c, { username => ? } );
  $c->model('User')->get($c, { email => ? } );

get() do not query database directly, it try to get from cache, if not exists, get_user_from_db() and set cache. return is a hashref: (we may call it $user_obj below)

  {
    user_id  => 1,
    username => 'fayland',
    # etc. from user table columns
    details  => {
        birthday => '1984-02-06',
        gtalk    => 'fayland'
        # etc. from user_details table columns
    },
    roles    => {
        1 => { admin => 1 },
        site => { admin => 1 },
        # etc. from user_roles, $field => { $role => 1 }
    }
    profile_photo => {
        type  => 'upload',
        value => 10,
        # etc. from user_profile_photo table columns
        upload => {
            upload_id => 10,
            filename  => 'fayland.jpg',
            # etc. from upload table columns
        }
    }
  }

=item get_multi

  $c->model('User')->get_multi($c, user_id => [1, 2, 3]  );
  $c->model('User')->get_multi($c, username => ['fayland', 'testman'] );

get_multi() is to ease a loop for many users. if cache backend is memcached, it would use $memcached->get_multi(); to get cached user, and use get_user_from_db() to missing users. return is a hashref:

  # $user_obj is the user hash above
  1 => $user_obj,
  2 => $user_obj,
  # or
  fayland => $user_obj,
  testman => $user_obj,

(TODO: we may use { user_id => { 'IN' => \@user_ids } } for missing users.)

=item get_user_from_db()

  $c->model('User')->get_user_from_db($c, { user_id => ? } );
  $c->model('User')->get_user_from_db($c, { username => ? } );
  $c->model('User')->get_user_from_db($c, { email => ? } );

query db directly. return $user_obj

=item update()

  $c->model('User')->update($c, $user_obj, { update_column => $value } );

the difference between $row->update of L<DBIx::Class> is that it delete cache.

=item delete_cache_by_user()

  $c->model('User')->delete_cache_by_user($c, $user_obj);

=item delete_cache_by_user_cond

  $c->model('User')->delete_cache_by_user_cond($c, { user_id => ? } );
  $c->model('User')->delete_cache_by_user_cond($c, { username => ? } );
  $c->model('User')->delete_cache_by_user_cond($c, { email => ? } );

=item get_user_settings

  $c->model('User')->get_user_settings($c, $user_obj);

get records from user_settings table. return is hashref

  {
    send_starred_notification => 'N',
  }

=back

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
