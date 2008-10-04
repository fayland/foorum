package Foorum::Model::Object;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Model';

sub get_object_from_url {
    my ( $self, $c, $path ) = @_;

    my ( $object_id, $object_type, $forum_code );

    # 1. poll, eg: /forum/ForumName/poll/2
    if ( $path =~ /\/forum\/(\w+)\/poll\/(\d+)/ ) {
        $forum_code  = $1;
        $object_id   = $2;       # poll_id
        $object_type = 'poll';
    }

    # 1, topic, eg: /forum/ForumName/topic/3
    if ( $path =~ /\/forum\/(\w+)\/topic\/(\d+)/ ) {
        $forum_code  = $1;
        $object_id   = $2;
        $object_type = 'topic';
    }

    # 2. user profile, eg: /u/fayland or /u/1
    elsif ( $path =~ /\/u\/(\w+)/ ) {
        my $user_sig = $1;
        if ( $user_sig =~ /^\d+$/ ) {
            $object_id = $user_sig;
        } else {
            my $user
                = $c->model('DBIC::User')->get( { username => $user_sig } );
            return unless ($user);
            $object_id = $user->{user_id};
        }
        $object_type = 'user_profile';
    }

    return ( $object_id, $object_type, $forum_code );
}

sub get_url_from_object {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    my $forum_id    = $info->{forum_id};

    if ( $object_type eq 'poll' ) {
        return "/forum/$forum_id/poll/$object_id";
    } elsif ( $object_type eq 'topic' ) {
        return "/forum/$forum_id/topic/$object_id";
    } elsif ( $object_type eq 'user_profile' ) {
        return "/u/$object_id";
    }
}

sub get_object_by_type_id {
    my ( $self, $c, $info ) = @_;

    my $object_type = $info->{object_type};
    my $object_id   = $info->{object_id};
    return unless ( $object_type and $object_id );

    if ( $object_type eq 'topic' ) {
        my $object = $c->model('DBIC::Topic')->get($object_id);
        return unless ($object);
        return {
            object_type => 'topic',
            object_id   => $object_id,
            title       => $object->{title},
            author      => $c->model('DBIC::User')
                ->get( { user_id => $object->{author_id} } ),
            url         => '/forum/' . $object->{forum_id} . "/$object_id",
            last_update => $object->{last_update_date},
            forum_id    => $object->{forum_id},
        };
    } elsif ( $object_type eq 'poll' ) {
        my $object
            = $c->model('DBIC::Poll')->find( { poll_id => $object_id, } );
        return unless ($object);
        return {
            object_type => 'poll',
            object_id   => $object_id,
            title       => $object->title,
            author      => $c->model('DBIC::User')
                ->get( { user_id => $object->author_id } ),
            url         => '/forum/' . $object->forum_id . "/poll/$object_id",
            last_update => '-',
            forum_id    => $object->forum_id,
        };
    }
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
