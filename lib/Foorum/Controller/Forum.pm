package Foorum::Controller::Forum;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;
use Data::Dumper;

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
        $_->{last_post} = $c->model('Topic')->get($c, $_->last_post_id );
        next unless $_->{last_post};
        $_->{last_post}->{updator} = $c->model('User')
            ->get( $c, { user_id => $_->{last_post}->{last_updator_id} } );
    }

    $c->cache_page('300');

    # get all moderators
    my @forum_ids;
    push @forum_ids, $_->forum_id foreach (@forums);
    if (scalar @forum_ids) {
        my $roles = $c->model('Policy')->get_forum_moderators( $c, \@forum_ids );
        $c->stash->{roles} = $roles;
    }

    $c->stash->{whos_view_this_page} = 1;
    $c->stash->{forums}              = \@forums;
    $c->stash->{template}            = 'forum/board.html';
}

sub forum_list : Regex('^forum/(\w+)$') {
    my ( $self, $c ) = @_;

    my $is_elite = ( $c->req->path =~ /\/elite(\/|$)/ ) ? 1 : 0;
    my $page_no  = get_page_from_url( $c->req->path );
    my $rss      = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0; # /forum/1/rss

    # get the forum information
    my $forum_code = $c->req->snippets->[0];
    my $forum      = $c->controller('Get')->forum( $c, $forum_code );
    my $forum_id   = $forum->{forum_id};
       $forum_code = $forum->{forum_code};

    my @extra_cols = ( 'elite', 1 ) if ($is_elite);
    my $it = $c->model('DBIC')->resultset('Topic')->search(
        {   forum_id    => $forum_id,
            'me.status' => { '!=', 'banned' },
            @extra_cols,
        },
        {   order_by => 'sticky DESC, last_update_date DESC',
            rows     => $c->config->{per_page}->{forum},
            page     => $page_no,
            prefetch => [ 'author', 'last_updator' ],
        }
    );
    my @topics = $it->all;

    if ($rss) {
        foreach (@topics) {
            my $rs = $c->model('DBIC::Comment')->find(
                {   object_type => 'topic',
                    object_id   => $_->topic_id,
                },
                {   order_by => 'post_on',
                    rows     => 1,
                    page     => 1,
                    columns  => ['text', 'formatter'],
                }
            );
            next unless ($rs);
            $_->{text} = $rs->text;
            # filter format by Foorum::Filter
            $_->{text} = $c->model('FilterWord')
                ->convert_offensive_word( $c, $_->{text} );
            $_->{text} = filter_format($_->{text}, { format => $rs->formatter });
        }
        $c->stash->{topics} = \@topics;
        $c->stash->{template} = 'forum/forum.rss.html';
        $c->cache_page('600');
        return;
    }
    # above is for RSS, left is for HTML

    # get all moderators
    $c->stash->{forum_roles}
        = $c->model('Policy')->get_forum_moderators( $c, $forum_id );

    # for page 1 and normal mode
    if ( $page_no == 1 and not $is_elite ) {

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
        my $ann_cookie = $c->req->cookie("ann_$forum_id");
        unless ( $ann_cookie and $ann_cookie->value ) {
            my $announcement = $c->model('DBIC::Comment')->find(
                {   object_type => 'announcement',
                    object_id   => $forum_id,
                },
                { columns => [ 'title', 'text' ], }
            );

            # filter format by Foorum::Filter
            $announcement->{_column_data}->{text}
                = filter_format( $announcement->{_column_data}->{text},
                { format => 'ubb' } )
                if ($announcement);
            $c->stash->{announcement} = $announcement;
            $c->res->cookies->{"ann_$forum_id"} = { value => 1 };
        }
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
        and $member_type ne 'rejected' )
    {
        $member_type = 'user';
    }

    my $page_no = get_page_from_url( $c->req->path );

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
            page => $page_no,
        }
    );
    my @user_roles = $rs->all;
    my @all_user_ids = map { $_->user_id } @user_roles;

    my @members;
    my %members;
    if ( scalar @all_user_ids ) {
        @members = $c->model('DBIC::User')->search(
            { user_id => { 'IN', \@all_user_ids }, },
            {   columns => [
                    'user_id', 'username', 'nickname', 'gender',
                    'register_on'
                ],
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
    
    my @all_user_ids; my %unique_user_ids;
    foreach (@actions) {
        next if ($unique_user_ids{$_->user_id});
        push @all_user_ids, $_->user_id;
        $unique_user_ids{$_->user_id} = 1;
    }
    if (scalar @all_user_ids) {
        my $authors = $c->model('User')->get_multi($c, 'user_id', \@all_user_ids);
        foreach (@actions) {
            $_->{operator} = $authors->{$_->user_id};
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
        my $rs = $c->model('DBIC::UserRole')->find(
            {   user_id => $c->user->user_id,
                field   => $forum_id,
            },
            { columns => ['role'], }
        );
        if ($rs) {
            if (   $rs->role eq 'user'
                or $rs->role eq 'moderator'
                or $rs->role eq 'admin' )
            {
                return $c->res->redirect( $forum->{forum_url} );
            } elsif ( $rs->role eq 'blocked'
                or $rs->role eq 'pending'
                or $rs->role eq 'rejected' )
            {
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
            $c->detach(
                '/print_message',
                [   'Successfully Requested. You need wait for admin\'s approval'
                ]
            );
        }
    } else {
        $c->stash(
            {   simple_wrapper => 1,
                template       => 'forum/join_us.html',
            }
        );
    }
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
