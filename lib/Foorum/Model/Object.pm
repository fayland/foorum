package Foorum::Model::Object;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;
use Switch;

sub get_object_from_url {
    my ( $self, $c, $path ) = @_;

    my ( $object_id, $object_type, $forum_code );

    # 1. poll, eg: /forum/ForumName/poll/2
    if ( $path =~ /\/forum\/(\w+)\/poll\/(\d+)/ ) {
        $forum_code  = $1;
        $object_id   = $2;       # poll_id
        $object_type = 'poll';
    }

    # 2. user profile, eg: /u/fayland
    elsif ( $path =~ /\/u\/(\w+)/ ) {
        my $user = $c->model('User')->get( $c, { username => $1 } );
        return unless ($user);
        $object_id   = $user->{user_id};
        $object_type = 'user_profile';
    }

    return ( $object_id, $object_type, $forum_code );
}

sub get_url_from_object {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $forum_id    = $info->{forum_id};

    switch ($object_type) {
        case 'poll' { return "/forum/$forum_id/poll/$object_id"; }
        case 'user_profile' {
            my $user
                = $c->model('User')->get( $c, { user_id => $object_id } );
            return '/u/' . $user->{username} if ($user);
        }
    }
}

sub get_object_by_type_id {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    return unless ( $object_type and $object_id );

    switch ($object_type) {
        case 'topic' {
            my $object = $c->model('Topic')->get($c, $object_id);
            return unless ($object);
            return {
                object_type => 'topic',
                title  => $object->{title},
                author => $c->model('User')->get($c, { user_id => $object->{author_id} } ),
                url    => '/forum/' . $object->{forum_id} . "/$object_id",
                last_update => $object->{last_update_date},
            };
        }
        case 'poll' {
            my $object = $c->model('DBIC::Poll')->find(
                {
                    poll_id => $object_id,
                }
            );
            return unless ($object_id);
            return {
                object_type => 'poll',
                title  => $object->title,
                author => $c->model('User')->get($c, { user_id => $object->author_id } ),
                url    => '/forum/' . $object->forum_id . "/poll/$object_id",
                last_update => '-',
            };
        }
    }
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
