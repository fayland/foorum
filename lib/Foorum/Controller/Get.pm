package Foorum::Controller::Get;

use strict;
use warnings;
use base 'Catalyst::Controller';

# Module Idea:
# we can't use /print_error in Model/Topic.pm like.
# so we move it here. Controller based.

sub forum : Private {
    my ($self, $c, $forum_code, $attr ) = @_;
    
    my $forum = $c->model('Forum')->get($c, $forum_code, $attr );
    
    # print error if the forum_id is non-exist
    $c->detach( '/print_error', ['Non-existent forum'] ) unless ($forum);
    $c->detach( '/print_error', ['Status: Banned'] )
        if ( $forum->{status} eq 'banned'
        and not $c->model('Policy')->is_moderator( $c, $forum->{forum_id} ) );

    my $forum_id = $forum->{forum_id};

    # check policy
    if (    $c->user_exists
        and $c->model('Policy')->is_blocked( $c, $forum_id ) )
    {
        $c->detach( '/print_error', ['ERROR_USER_BLOCKED'] );
    }
    if ( $forum->{policy} eq 'private' ) {
        unless ( $c->user_exists ) {
            $c->res->redirect('/login');
            $c->detach('/end');    # guess we'd better use Chained
        }

        unless ( $c->model('Policy')->is_user( $c, $forum_id ) ) {
            if ( $c->model('Policy')->is_pending( $c, $forum_id ) ) {
                $c->detach( '/print_error', ['ERROR_USER_PENDING'] );
            } elsif ( $c->model('Policy')->is_rejected( $c, $forum_id ) ) {
                $c->detach( '/print_error', ['ERROR_USER_REJECTED'] );
            } else {
                $c->detach( '/forum/join_us', [$forum] );
            }
        }
    }

    $c->stash->{forum} = $forum;
    return $forum;
}

sub topic : Private {
    my ($self, $c, $topic_id, $attrs) = @_;
    
    my $topic = $c->model('Topic')->get($c, $topic_id, $attrs);
    
    # print error if the topic is non-existent
    $c->detach( '/print_error', ['Non-existent topic'] ) unless ($topic);
    
    # check forum_id
    if ($attrs->{forum_id} and $attrs->{forum_id} != $topic->{forum_id}) {
        $c->detach( '/print_error', ['Non-existent topic'] );
    }
    
    my $forum_id = $topic->{forum_id};
    $c->detach( '/print_error', ['Status: Banned'] )
        if ( $topic->{status} eq 'banned'
        and not $c->model('Policy')->is_moderator( $c, $forum_id ) );
    
    $c->stash->{topic} = $topic;
    return $topic;
}

sub user : Private {
    my ($self, $c, $username) = @_;
    
    my $user = $c->model('User')->get($c, { username => $username } );
    
    $c->detach( '/print_error', ['ERROR_USER_NON_EXSIT'] ) unless ($user);
    
    if ($user->{status} eq 'banned' or $user->{status} eq 'blocked') {
        $c->detach('/print_error', [ 'ERROR_ACCOUNT_CLOSED_STATUS' ] );
    }

    $c->stash->{user} = $user;
    return $user;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
