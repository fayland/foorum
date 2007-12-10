package Foorum::Controller::Topic;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;
use Foorum::Utils qw/encodeHTML get_page_from_url/;

sub topic : Regex('^forum/(\w+)/(\d+)$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $topic_id   = $c->req->snippets->[1];
    my $page_no    = get_page_from_url( $c->req->path );
    $page_no = 1 unless ( $page_no and $page_no =~ /^\d+$/ );

    # get the forum information
    my $forum = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id = $forum->{forum_id};

    # get the topic
    my $topic = $c->controller('Get')->topic( $c, $topic_id, { forum_id => $forum_id } );
    
    $topic->{hit} = $c->model('Hit')->register($c, 'topic', $topic_id, $topic->{hit});

    if ( $c->user_exists ) {

        # 'star' status
        $c->stash->{has_star} = $c->model('DBIC::Star')->count(
            {   user_id     => $c->user->user_id,
                object_type => 'topic',
                object_id   => $topic_id,
            }
        );

        # 'visit'
        $c->model('Visit')->make_visited( $c, 'topic', $topic_id );
    }

    # get comments
    $c->model('Comment')->get_comments_by_object(
        $c,
        {   object_type => 'topic',
            object_id   => $topic_id,
            page        => $page_no,
        }
    );

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{template}            = 'topic/index.html';
}

sub create : Regex('^forum/(\w+)/topic/new$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    &_check_policy( $self, $c );

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};

    $c->stash(
        {   template => 'topic/create.html',
            action   => 'create',
        }
    );

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id = $c->model('Upload')
            ->add_file( $c, $upload, { forum_id => $forum_id } );
        unless ($upload_id) {
            return $c->set_invalid_form(
                upload => $c->stash->{upload_error} );
        }
    }

    # we prefer [% | html %] now because of my bad memory in TT html
    my $title = $c->req->param('title');
    $title = encodeHTML($title);

    # create record
    my $topic = $c->model('DBIC')->resultset('Topic')->create(
        {   forum_id         => $forum_id,
            title            => $title,
            author_id        => $c->user->user_id,
            last_updator_id  => $c->user->user_id,
            last_update_date => \"NOW()",
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
        }
    );

    # update user stat
    $c->model('User')->update(
        $c,
        $c->user,
        {   threads      => \"threads + 1",
            last_post_id => $topic->topic_id,
        }
    );

    # update forum
    $c->model('Forum')->update($c, $forum_id,
        {   total_topics => \'total_topics + 1', #'
            last_post_id => $topic->topic_id,
        }
    );

    $c->res->redirect( $forum->{forum_url} . '/' . $topic->topic_id );
}

sub reply : Regex('^forum/(\w+)/(\d+)(/(\d+))?/reply$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    &_check_policy( $self, $c );

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    my $topic_id   = $c->req->snippets->[1];
    my $topic      = $c->controller('Get')->topic( $c, $topic_id, { forum_id => $forum_id } );
    my $comment_id = $c->req->snippets->[3];

    # topic is closed or not
    $c->detach( '/print_error', ['ERROR_CLOSED'] ) if ( $topic->{closed} );

    $c->stash->{template} = 'comment/reply.html';

    unless ( $c->req->method eq 'POST' ) {
        my $comment = $c->model('Comment')->get(
            $c,
            $comment_id,
            {   object_type => 'topic',
                object_id   => $topic_id,
                with_author => 1,
                with_text   => 1
            }
        ) if ($comment_id);
        return;
    }

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    return if ( $c->form->has_error );

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id = $c->model('Upload')
            ->add_file( $c, $upload, { forum_id => $forum_id } );
        unless ($upload_id) {
            return $c->set_invalid_form(
                upload => $c->stash->{upload_error} );
        }
    }

    $comment_id = $topic_id unless ($comment_id);
    my $comment = $c->model('Comment')->create(
        $c,
        {   object_type => 'topic',
            object_id   => $topic_id,
            forum_id    => $forum_id,
            upload_id   => $upload_id,
            reply_to    => $comment_id,
        }
    );

    # update forum and topic
    $c->model('Forum')->update($c, $forum_id,
        {   total_replies => \'total_replies + 1',
            last_post_id  => $topic_id,
        }
    );
    $c->model('Topic')->update( $c, $topic_id, {
        total_replies    => \"total_replies + 1",
        last_update_date => \"NOW()",
        last_updator_id  => $c->user->user_id,
    } );
 
    # update user stat
    $c->model('User')->update(
        $c,
        $c->user,
        {   replies      => \"replies + 1",
            last_post_id => $topic_id,
        }
    );

    $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );

    $c->forward(
        '/print_message',
        [   {   msg => 'Post Reply OK',
                url => $forum->{forum_url} . "/$topic_id",
            }
        ]
    );
}

sub edit : Regex('^forum/(\w+)/(\d+)/(\d+)/edit$') {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    &_check_policy( $self, $c );

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    my $topic_id   = $c->req->snippets->[1];
    my $topic      = $c->controller('Get')->topic( $c, $topic_id, { forum_id => $forum_id } );
    my $comment_id = $c->req->snippets->[2];
    my $comment
        = $c->model('Comment')
        ->get( $c, $comment_id,
        { object_type => 'topic', object_id => $topic_id } );

    # permission
    if ( $c->user->user_id != $comment->author_id
        and not $c->model('Policy')->is_moderator( $c, $forum_id ) )
    {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash->{template} = 'comment/edit.html';

    # edit upload
    my $old_upload;
    if ( $comment->upload_id ) {
        $old_upload = $c->model('DBIC::Upload')
            ->find( { upload_id => $comment->upload_id } );
    }
    $c->stash->{upload} = $old_upload;

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    return if ( $c->form->has_error );

    my $new_upload = $c->req->upload('upload');
    my $upload_id  = $comment->upload_id;
    if ( ( $c->req->param('attachment_action') eq 'delete' ) or $new_upload )
    {

        # delete old upload
        if ($old_upload) {
            $c->model('Upload')->remove_by_upload( $c, $old_upload );
            $upload_id = 0;
        }
        if ($new_upload) {
            $upload_id
                = $c->model('Upload')
                ->add_file( $c, $new_upload,
                { forum_id => $comment->forum_id } );
            unless ($upload_id) {
                return $c->set_invalid_form(
                    upload => $c->stash->{upload_error} );
            }
        }
    }

    my $title = $c->req->param('title');
    $title = encodeHTML($title);
    $comment->update(
        {   title     => $title,
            text      => $c->req->param('text'),
            formatter => 'ubb',
            update_on => \'NOW()',
            post_ip   => $c->req->address,
            upload_id => $upload_id,
        }
    );

    if (    $comment->reply_to == 0
        and $topic->{title} ne $c->req->param('title') )
    {
        $c->model('Topic')->update( $c, $topic_id, { title => $c->req->param('title') } );
        $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );
    }

    my $cache_key = "comment|object_type=topic|object_id=$topic_id";
    $c->cache->delete($cache_key);

    $c->forward(
        '/print_message',
        [   {   msg => 'Edit Reply OK',
                url => $forum->{forum_url} . "/$topic_id",
            }
        ]
    );
}

sub delete : Regex('^forum/(\w+)/(\d+)/(\d+)/delete$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    my $topic_id   = $c->req->snippets->[1];
    my $comment_id = $c->req->snippets->[2];
    my $comment
        = $c->model('Comment')
        ->get( $c, $comment_id,
        { object_type => 'topic', object_id => $topic_id } );

    # permission
    if ( $c->user->user_id != $comment->author_id
        and not $c->model('Policy')->is_moderator( $c, $forum_id ) )
    {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    my $url;
    if ( $comment->reply_to == 0 ) {

        # u can only delete 5 topics one day
        my $most_deletion_per_day
            = $c->config->{topic}->{most_deletion_per_day}
            || 5;
        my $deleted_count = $c->model('DBIC')->resultset('LogAction')->count(
            {   forum_id => $forum_id,
                action   => 'delete',
                time     => \"> DATE_SUB(NOW(), INTERVAL 1 DAY)"
            }
        );
        if ( $deleted_count >= $most_deletion_per_day ) {
            $c->detach(
                '/print_error',
                [   "For security reason, you can't delete more than $most_deletion_per_day topics in one day"
                ]
            );
        }

        $c->model('Topic')->remove( $c, $forum_id, $topic_id,
            { log_text => $comment->title } );
        $url = $forum->{forum_url};
        $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );
    } else {

        # delete comment
        $c->model('Comment')->remove( $c, $comment );

        $url = $forum->{forum_url} . "/$topic_id";

        # update topic
        my $lastest = $c->model('DBIC')->resultset('Comment')->find(
            {   object_type => 'topic',
                object_id   => $topic_id,
            },
            { order_by => 'post_on DESC', }
        );

        my @extra_cols;
        if ($lastest) {
            @extra_cols = (
                last_updator_id  => $lastest->author_id,
                last_update_date => $lastest->update_on || $lastest->post_on,
            );
        } else {
            @extra_cols = (
                last_updator_id  => '',
                last_update_date => '',
            );
        }
        $c->model('Topic')->update( $c, $topic_id, { total_replies => \"total_replies - 1",
            @extra_cols,
        } );
        
        # update forum
        $c->model('Forum')->update($c, $forum_id, { total_replies => \'total_replies - 1' } );
    }

    $c->forward(
        '/print_message',
        [   {   msg => 'Delete Reply OK',
                url => $url,
            }
        ]
    );
}

sub _check_policy {
    my ( $self, $c ) = @_;

    # check policy
    if ( $c->user->{status} eq 'banned' or $c->user->{status} eq 'blocked' ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
