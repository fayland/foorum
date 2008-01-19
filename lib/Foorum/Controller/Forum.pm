package Foorum::Controller::Forum;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;

sub board : Path {
    my ( $self, $c ) = @_;

    my @forums = $c->model('DBIC')->resultset('Forum')->search(
        {   forum_type => 'classical',
            status     => { '!=', 'banned' },
        },
        { order_by => 'me.forum_id', }
    )->all;

    # get last_post and the author
    foreach (@forums) {
        next unless $_->last_post_id;
        $_->{last_post} = $c->model('Topic')->get( $c, $_->last_post_id );
        next unless $_->{last_post};
        $_->{last_post}->{updator} = $c->model('User')
            ->get( $c, { user_id => $_->{last_post}->{last_updator_id} } );
    }

    $c->cache_page('300');

    # get all moderators
    my @forum_ids;
    push @forum_ids, $_->forum_id foreach (@forums);
    if ( scalar @forum_ids ) {
        my $roles = $c->model('Policy')->get_forum_moderators( $c, \@forum_ids );
        $c->stash->{forum_roles} = $roles;
    }

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{forums}              = \@forums;
    $c->stash->{template}            = 'forum/board.html';
}

sub forum_list : Regex('^forum/(\w+)$') {
    my ( $self, $c ) = @_;

    my $is_elite = ( $c->req->path =~ /\/elite(\/|$)/ ) ? 1 : 0;
    my $page     = get_page_from_url( $c->req->path );
    my $rss      = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0;     # /forum/1/rss

    # get the forum information
    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
    $forum_code = $forum->{forum_code};

    my @extra_cols = ($is_elite) ? ( 'elite', 1 ) : ();
    my $rows = ($rss) ? 10 : $c->config->{per_page}->{forum};      # 10 for RSS is enough
    my $it = $c->model('DBIC')->resultset('Topic')->search(
        {   forum_id    => $forum_id,
            'me.status' => { '!=', 'banned' },
            @extra_cols,
        },
        {   order_by => 'sticky DESC, last_update_date DESC',
            rows     => $rows,
            page     => $page,
            prefetch => [ 'author', 'last_updator' ],
        }
    );
    my @topics = $it->all;

    if ($rss) {
        foreach (@topics) {
            my $rs = $c->model('DBIC::Comment')->search(
                {   object_type => 'topic',
                    object_id   => $_->topic_id,
                },
                {   order_by => 'post_on',
                    rows     => 1,
                    page     => 1,
                    columns  => [ 'text', 'formatter' ],
                }
            )->first;
            next unless ($rs);
            $_->{text} = $rs->text;

            # filter format by Foorum::Filter
            $_->{text}
                = $c->model('DBIC::FilterWord')->convert_offensive_word( $_->{text} );
            $_->{text} = filter_format( $_->{text}, { format => $rs->formatter } );
        }
        $c->stash->{topics}   = \@topics;
        $c->stash->{template} = 'forum/forum.rss.html';
        $c->cache_page('600');
        return;
    }

    # above is for RSS, left is for HTML

    # get all moderators
    $c->stash->{forum_roles} = $c->model('Policy')->get_forum_moderators( $c, $forum_id );

    # for page 1 and normal mode
    if ( $page == 1 and not $is_elite ) {

        # for private forum
        if ( $forum->{policy} eq 'private' ) {
            my $pending_count = $c->model('DBIC::UserRole')->count(
                {   field => $forum_id,
                    role  => 'pending',
                }
            );
            $c->stash( { pending_count => $pending_count, } );
        }

        # check announcement
        $c->stash->{announcement} = $c->model('Forum')->get_announcement( $c, $forum );
    }

    $c->cache_page('300');

    if ( $c->user_exists ) {
        my @all_topic_ids = map { $_->topic_id } @topics;
        $c->stash->{is_visited}
            = $c->model('Visit')->is_visited( $c, 'topic', \@all_topic_ids )
            if ( scalar @all_topic_ids );
    }

    # Pager
    my $pager = $it->pager;

    # For Tabs
    $c->stash->{poll_count} = $c->model('DBIC')->resultset('Poll')->count(
        {   forum_id => $forum_id,
            duration => { '>', time() },
        }
    );

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{pager}               = $pager;
    $c->stash->{topics}              = \@topics;
    $c->stash->{template}            = 'forum/forum.html';
}

sub members : LocalRegex('^(\w+)/members(/(\w+))?$') {
    my ( $self, $c ) = @_;

    my $forum_code  = $c->req->snippets->[0];
    my $member_type = $c->req->snippets->[2];
    my $forum       = $c->controller('Get')->forum( $c, $forum_code );
    $forum_code = $forum->{forum_code};
    my $forum_id = $forum->{forum_id};

    if (    $member_type ne 'pending'
        and $member_type ne 'blocked'
        and $member_type ne 'rejected' ) {
        $member_type = 'user';
    }

    my $page = get_page_from_url( $c->req->path );

    my ( @query_cols, @attr_cols );
    if ( $member_type eq 'user' ) {
        @query_cols = ( 'role', [ 'admin', 'moderator', 'user' ] );
        @attr_cols = ( 'order_by' => 'role ASC' );
    } else {
        @query_cols = ( 'role', $member_type );
    }
    my $rs = $c->model('DBIC::UserRole')->search(
        { @query_cols, field => $forum_id, },
        {   @attr_cols,
            rows => 20,
            page => $page,
        }
    );
    my @user_roles = $rs->all;
    my @all_user_ids = map { $_->user_id } @user_roles;

    my @members;
    my %members;
    if ( scalar @all_user_ids ) {
        @members = $c->model('DBIC::User')->search(
            { user_id => { 'IN', \@all_user_ids }, },
            {   columns =>
                    [ 'user_id', 'username', 'nickname', 'gender', 'register_time' ],
            }
        )->all;
        %members = map { $_->user_id => $_ } @members;
    }

    my $url_prefix = $forum->{forum_url} . '/members';
    $url_prefix .= "/$member_type" if ($member_type);

    $c->stash(
        {   template            => 'forum/members.html',
            member_type         => $member_type,
            pager               => $rs->pager,
            url_prefix          => $url_prefix,
            user_roles          => \@user_roles,
            whos_view_this_page => 1,
            members             => \%members,
        }
    );
}

sub action_log : LocalRegex('^(\w+)/action_log(/(\w+))?$') {
    my ( $self, $c ) = @_;

    my $forum_code = $c->req->snippets->[0];
    my $log_type   = $c->req->snippets->[2];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    $forum_code = $forum->{forum_code};
    my $forum_id = $forum->{forum_id};

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC')->resultset('LogAction')->search(
        { forum_id => $forum_id, },
        {   order_by => 'time DESC',
            page     => $page,
            rows     => 20,
        }
    );

    my @actions = $rs->all;

    my @all_user_ids;
    my %unique_user_ids;
    foreach (@actions) {
        next if ( $unique_user_ids{ $_->user_id } );
        push @all_user_ids, $_->user_id;
        $unique_user_ids{ $_->user_id } = 1;
    }
    if ( scalar @all_user_ids ) {
        my $authors = $c->model('User')->get_multi( $c, 'user_id', \@all_user_ids );
        foreach (@actions) {
            $_->{operator} = $authors->{ $_->user_id };
        }
    }

    $c->stash(
        {   template => 'forum/action_log.html',
            pager    => $rs->pager,
            logs     => \@actions,
        }
    );
}

sub join_us : Private {
    my ( $self, $c, $forum ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $forum_id = $forum->{forum_id};

    if ( $c->req->method eq 'POST' ) {
        my $rs = $c->model('DBIC::UserRole')->search(
            {   user_id => $c->user->user_id,
                field   => $forum_id,
            },
            { columns => ['role'], }
        )->first;
        if ($rs) {
            if (   $rs->role eq 'user'
                or $rs->role eq 'moderator'
                or $rs->role eq 'admin' ) {
                return $c->res->redirect( $forum->{forum_url} );
            } elsif ( $rs->role eq 'blocked'
                or $rs->role eq 'pending'
                or $rs->role eq 'rejected' ) {
                my $role = uc( $rs->role );
                $c->detach( '/print_error', ["ERROR_USER_$role"] );
            }
        } else {
            $c->model('Policy')->create_user_role(
                $c,
                {   user_id => $c->user->user_id,
                    field   => $forum_id,
                    role    => 'pending',
                }
            );
            $c->detach( '/print_message',
                ['Successfully Requested. You need wait for admin\'s approval'] );
        }
    } else {
        $c->stash(
            {   simple_wrapper => 1,
                template       => 'forum/join_us.html',
            }
        );
    }
}

sub create : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    my $is_admin = $c->model('Policy')->is_admin( $c, 'site' );

    # if function_on.create_forum is off, check is admin
    if ( not $c->config->{function_on}->{create_forum} and not $is_admin ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash( { template => 'forum/create.html' } );

    return unless ( $c->req->method eq 'POST' );

    $c->form(
        name        => [ qw/NOT_BLANK/, [qw/LENGTH 1 40/] ],
        description => [ qw/NOT_BLANK/, [qw/LENGTH 1 200/] ],
    );
    return if ( $c->form->has_error );

    # check forum_code
    my $forum_code = $c->req->param('forum_code');
    my $err = $c->model('Validation')->validate_forum_code( $c, $forum_code );
    if ($err) {
        $c->set_invalid_form( forum_code => $err );
        return;
    }

    my $name        = $c->req->param('name');
    my $description = $c->req->param('description');
    my $moderators  = $c->req->param('moderators');
    my $private     = $c->req->param('private');

    # validate the admin for roles.site.admin
    my $admin_user;
    if ($is_admin) {
        my $admin = $c->req->param('admin');
        $admin_user = $c->model('User')->get( $c, { username => $admin } );
        unless ($admin_user) {
            return $c->set_invalid_form( admin => 'ADMIN_NONEXISTENCE' );
        }
    } else {
        $admin_user = $c->user;
    }

    # validate the moderators
    my $total_members = 1;
    my @moderators = split( /\s*\,\s*/, $moderators );
    my @moderator_users;
    foreach (@moderators) {
        next if ( $_ eq $admin_user->{username} );    # avoid the same man
        last
            if ( scalar @moderator_users > 2 );       # only allow 3 moderators at most
        my $moderator_user = $c->model('User')->get( $c, { username => $_ } );
        unless ($moderator_user) {
            $c->stash->{non_existence_user} = $_;
            return $c->set_invalid_form( moderators => 'ADMIN_NONEXISTENCE' );
        }
        $total_members++;
        push @moderator_users, $moderator_user;
    }

    # insert data into table.
    my $policy = ( $private == 1 ) ? 'private' : 'public';
    my $forum = $c->model('DBIC::Forum')->create(
        {   name          => $name,
            forum_code    => $forum_code,
            description   => $description,
            forum_type    => 'classical',
            policy        => $policy,
            total_members => $total_members,
        }
    );
    $c->model('Policy')->create_user_role(
        $c,
        {   user_id => $admin_user->{user_id},
            role    => 'admin',
            field   => $forum->forum_id,
        }
    );
    foreach (@moderator_users) {
        $c->model('Policy')->create_user_role(
            $c,
            {   user_id => $_->{user_id},
                role    => 'moderator',
                field   => $forum->forum_id,
            }
        );
    }

    $c->res->redirect("/forum/$forum_code");
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
