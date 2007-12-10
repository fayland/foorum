package Foorum::Controller::ForumAdmin;

use strict;
use warnings;
use base 'Catalyst::Controller';
use File::Slurp;
use YAML::Syck;
use Foorum::Utils qw/is_color encodeHTML/;
use Data::Dumper;

sub forum_for_admin : PathPart('forumadmin') Chained('/') CaptureArgs(1) {
    my ( $self, $c, $forum_code ) = @_;

    my $forum = $c->controller('Get')->forum( $c, $forum_code );

    unless ( $c->model('Policy')->is_admin( $c, $forum->{forum_id} ) ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

}

sub home : PathPart('') Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'forumadmin/index.html';
}

sub basic : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    $c->stash( { template => 'forumadmin/basic.html', } );

    $c->stash->{is_site_admin} = $c->model('Policy')->is_admin( $c, 'site' );

    my $role = $c->model('Policy')->get_forum_moderators( $c, $forum_id );
    unless ( $c->req->method eq 'POST' ) {

        # get all moderators
        my $e_moderators = $role->{$forum_id}->{moderator};
        if ($e_moderators) {
            my @e_moderators = @{$e_moderators};
            my @moderator_username;
            push @moderator_username, $_->{username} foreach (@e_moderators);
            $c->stash->{moderators} = join( ',', @moderator_username );
        }
        $c->stash->{private} = ( $forum->{policy} eq 'private' ) ? 1 : 0;
        return;
    }

    # validate
    $c->form(
        name => [ qw/NOT_BLANK/, [qw/LENGTH 1 40/] ],

        #        description  => [qw/NOT_BLANK/ ],
    );
    return if ( $c->form->has_error );

    # check forum_code
    my $forum_code = $c->req->param('forum_code');
    my $err = $c->model('Validation')->validate_forum_code( $c, $forum_code )
        if ( $forum_code and $forum_code ne $forum->{forum_code} );
    if ($err) {
        $c->set_invalid_form( forum_code => $err );
        return;
    }

    my $name        = $c->req->param('name');
    my $description = $c->req->param('description');
    my $moderators  = $c->req->param('moderators');
    my $private     = $c->req->param('private');

    # get forum admin
    my $admin = $role->{$forum_id}->{admin};
    my $admin_username = $admin->{username} if ($admin);

    my @moderators = split( /\s*\,\s*/, $moderators );
    my @moderator_users;
    foreach (@moderators) {
        next if ( $_ eq $admin_username );    # avoid the same man
        last
            if ( scalar @moderator_users > 2 )
            ;    # only allow 3 moderators at most
        my $moderator_user = $c->model('User')->get( $c, { username => $_ } );
        unless ($moderator_user) {
            $c->stash->{non_existence_user} = $_;
            return $c->set_invalid_form( moderators => 'ADMIN_NONEXISTENCE' );
        }
        push @moderator_users, $moderator_user;
    }

    # escape html for name and description
    $name        = encodeHTML($name);
    $description = encodeHTML($description);

    # insert data into table.
    my $policy = ( $private == 1 ) ? 'private' : 'public';
    my @extra_update;
    push @extra_update, ( forum_code => $forum_code )
        if ( $c->stash->{is_site_admin} );
    $c->model('Forum')->update($c, $forum_id,
        {   name        => $name,
            description => $description,

            #        type => 'classical',
            policy => $policy,
            @extra_update,
        }
    );

    # delete before create
    $c->model('Policy')->remove_user_role(
        $c,
        {   role  => 'moderator',
            field => $forum->{forum_id},
        }
    );
    foreach (@moderator_users) {
        $c->model('Policy')->create_user_role(
            $c,
            {   user_id => $_->user_id,
                role    => 'moderator',
                field   => $forum->{forum_id},
            }
        );
    }

    my $forum_url = $c->model('Forum')->get_forum_url( $c, $forum );
    $c->res->redirect($forum_url);
}

sub style : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    $c->stash->{template} = 'forumadmin/style.html';

    # style.yml and style.css
    my $yml
        = $c->path_to( 'style', 'custom', "forum$forum_id\.yml" )->stringify;

    unless ( $c->req->method eq 'POST' ) {
        if ( -e $yml ) {
            my $style = LoadFile($yml);
            $c->stash->{style} = $style;
        }
        return;
    }

    # execute validation.
    $c->form(
        bg_color         => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        bg_fontcolor     => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        alink            => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        vlink            => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        hlink            => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        tablebordercolor => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        titlecolor       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        titlefont        => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        forumcolor1      => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        forumfont1       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        forumcolor2      => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        forumfont2       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        replycolor1      => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        replyfont1       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        replycolor2      => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        replyfont2       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        misccolor1       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        miscfont1        => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        misccolor2       => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        miscfont2        => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        highlight        => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        semilight        => [ [ 'REGEX',   qr/^\#[0-9a-zA-Z]{6}$/ ] ],
        tablewidth       => [ [ 'BETWEEN', 70, 100 ] ],
        bg_image => [ 'HTTP_URL', [ 'REGEX', qr/^(gif|jpe?g|png)$/ ] ],
    );

    return if ( $c->form->has_error );

    # save the style.yml and style.css
    my $css = $c->path_to( 'root', 'static', 'css', 'custom',
        "forum$forum_id\.css" )->stringify;

    my $style = $c->req->params;

    my $css_content = $c->view('TT')->render(
        $c,
        'style/style.css',
        {   no_wrapper => 1,
            style      => $style,
        }
    );

    #    write_file($css, $css_content);
    if ( open( FH, '>', $css ) ) {
        flock( FH, 2 );
        print FH $css_content;
        close(FH);
    }

    my $yml_content = $c->view('TT')->render(
        $c,
        'style/style.yml',
        {   no_wrapper => 1,
            style      => $style,
        }
    );

    #    write_file($yml, $yml_content);
    if ( open( FH, '>', $yml ) ) {
        flock( FH, 2 );
        print FH $yml_content;
        close(FH);
    }

    $c->res->redirect( $forum->{forum_url} );
}

sub del_style : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    my $yml
        = $c->path_to( 'style', 'custom', "forum$forum_id\.yml" )->stringify;
    my $css = $c->path_to( 'root', 'static', 'css', 'custom',
        "forum$forum_id\.css" )->stringify;

    unlink $yml if ( -e $yml );
    unlink $css if ( -e $css );

    $c->res->redirect( $forum->{forum_url} );
}

sub announcement : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    my $announce = $c->model('DBIC::Comment')->find(
        {   object_id   => $forum_id,
            object_type => 'announcement',
        }
    );

    unless ( $c->req->method eq 'POST' ) {
        $c->stash(
            {   template => 'forumadmin/announcement.html',
                announce => $announce,
            }
        );
        return;
    }

    my $title = $c->req->param('title');
    my $text  = $c->req->param('text');

    # if no text is typed, delete the record.
    # or else, save it.
    if ( length($text) and length($title) ) {
        if ($announce) {
            $title = encodeHTML($title);
            $announce->update(
                {   text      => $text,
                    update_on => \"NOW()",
                    author_id => $c->user->user_id,
                    title     => $title,
                }
            );
        } else {
            $c->model('Comment')->create(
                $c,
                {   object_type => 'announcement',
                    object_id   => $forum_id,
                    forum_id    => $forum_id,
                }
            );
        }
    } else {
        $c->model('DBIC::Comment')->search(
            {   object_id   => $forum_id,
                object_type => 'announcement',
            }
        )->delete;
    }

    $c->res->redirect( $forum->{forum_url} );
}

# it's an ajax request
sub change_membership : Chained('forum_for_admin') Args(0) {
    my ( $self, $c ) = @_;

    my $forum    = $c->stash->{forum};
    my $forum_id = $forum->{forum_id};

    # get params;
    my $from    = $c->req->param('from');
    my $to      = $c->req->param('to');
    my $user_id = $c->req->param('user_id');

    unless ( grep { $from eq $_ } ( 'user', 'rejected', 'blocked', 'pending' )
            and grep { $to eq $_ } ( 'user', 'rejected', 'blocked' )
            and $user_id =~ /^\d+$/ )
    {
        return $c->res->body('Illegal request');
    }

    my $rs = $c->model('DBIC::UserRole')->count(
        {   field   => $forum_id,
            user_id => $user_id,
            role    => $from,
        }
    );
    return $c->res->body('no record available') unless ($rs);

    if ( $from eq 'user' and ( $to eq 'rejected' or $to eq 'blocked' ) ) {
        $c->model('Forum')->update($c, $forum_id, { total_members => \"total_members - 1" } );
    } elsif (
        ( $from eq 'rejected' or $from eq 'blocked' or $from eq 'pending' )
        and $to eq 'user' )
    {
        $c->model('Forum')->update($c, $forum_id, { total_members => \"total_members + 1" } );
    }

    my $where = {
        field   => $forum_id,
        user_id => $user_id,
        role    => $from,
    };
    $c->model('DBIC::UserRole')->search($where)->update( { role => $to } );
    $c->model('Policy')->clear_cached_policy( $c, $where );

    $c->res->body('OK');
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
