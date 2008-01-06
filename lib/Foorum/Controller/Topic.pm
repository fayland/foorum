package Foorum::Controller::Topic;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/encodeHTML get_page_from_url/;

sub topic : Regex('^forum/(\w+)/(topic/)?(\d+)$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $topic_id   = $c->req->snippets->[2];
    my $page       = get_page_from_url( $c->req->path );
    $page = 1 unless ( $page and $page =~ /^\d+$/ );
    my $rss = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0;    # /forum/ForumName/1/rss

    # get the forum information
    my $forum = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id = $forum->{forum_id};

    # get the topic
    my $topic = $c->controller('Get')->topic( $c, $topic_id, { forum_id => $forum_id } );

    if ($rss) {
        my @comments
            = $c->model('Comment')->get_all_comments_by_object( $c, 'topic', $topic_id );

        # get last 20 items
        @comments = reverse(@comments);
        @comments = splice( @comments, 0, 20 );

        $c->stash(
            {   comments => \@comments,
                template => 'topic/topic.rss.html'
            }
        );
    } else {
        $topic->{hit}
            = $c->model('Hit')->register( $c, 'topic', $topic_id, $topic->{hit} );
        if ( $c->user_exists ) {
            my $query = {
                user_id     => $c->user->user_id,
                object_type => 'topic',
                object_id   => $topic_id,
            };

            # 'star' status
            $c->stash->{is_starred} = $c->model('DBIC::Star')->count($query);

            # 'share' status
            $c->stash->{is_shared} = $c->model('DBIC')->resultset('Share')->count($query);

            # 'visit'
            $c->model('Visit')->make_visited( $c, 'topic', $topic_id );
        }

        # get comments
        $c->model('Comment')->get_comments_by_object(
            $c,
            {   object_type => 'topic',
                object_id   => $topic_id,
                page        => $page,
            }
        );
        $c->stash->{whos_view_this_page} = 1;
        $c->stash->{template}            = 'topic/index.html';
    }
}

sub create : Regex('^forum/(\w+)/topic/new$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    # check policy
    if ( $c->user->{status} eq 'banned' or $c->user->{status} eq 'blocked' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};

    if (    $forum->{settings}->{can_post_threads}
        and $forum->{settings}->{can_post_threads} eq 'N' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash(
        {   template => 'comment/new.html',
            mode     => 'topic',
            action   => 'create',
        }
    );

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id
            = $c->model('Upload')->add_file( $c, $upload, { forum_id => $forum_id } );
        unless ($upload_id) {
            return $c->set_invalid_form( upload => $c->stash->{upload_error} );
        }
    }

    my $title     = $c->req->param('title');
    my $formatter = $c->req->param('formatter');
    my $text      = $c->req->param('text');

    # only admin has HTML rights
    if ( $formatter eq 'html' ) {
        my $is_admin = $c->model('Policy')->is_admin( $c, 'site' );
        $formatter = 'plain' unless ($is_admin);
    }

    # create record
    my $topic_title = encodeHTML($title);
    my $topic       = $c->model('Topic')->create(
        $c,
        {   forum_id         => $forum_id,
            title            => $topic_title,
            author_id        => $c->user->user_id,
            last_updator_id  => $c->user->user_id,
            last_update_date => \"NOW()",            #"
            hit              => 0,
        }
    );
    $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );

    # clear visit
    $c->model('Visit')->make_un_visited( $c, 'topic', $topic->topic_id );

    my $comment = $c->model('Comment')->create(
        $c,
        {   object_type => 'topic',
            object_id   => $topic->topic_id,
            forum_id    => $forum_id,
            upload_id   => $upload_id,
            title       => $title,
            text        => $text,
            formatter   => $formatter,
        }
    );

    # update user stat
    $c->model('User')->update( $c, $c->user, { threads => \"threads + 1", } );    #"

    # update forum
    $c->model('Forum')->update(
        $c,
        $forum_id,
        {   total_topics => \'total_topics + 1',                                  #'
            last_post_id => $topic->topic_id,
        }
    );

    $c->res->redirect( $forum->{forum_url} . '/topic/' . $topic->topic_id );
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
