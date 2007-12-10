package Foorum::Model::Log;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;
use Foorum::Log qw/error_log/;

sub log_path {
    my ( $self, $c, $loadtime ) = @_;

    # sometimes we won't logger path because it expandes the table too quickly
    return unless ( $c->config->{logger}->{path} );
    return if ( $c->stash->{donot_log_path} );

# but sometimes we want to know which url is causing more than $PATH_LOAD_TIME_MORE_THAN
    return
        if ( $loadtime < $c->config->{logger}->{path_load_time_more_than} );

    my $path = $c->req->path;
    $path = ($path) ? substr( $path, 0, 255 ) : 'forum';    # varchar(255)
    my $get = $c->req->uri->query;
    $get = substr( $get, 0, 255 ) if ($get);                # varchar(255)
    my $post = $c->req->body_parameters;
    $post
        = ( keys %$post )
        ? substr( Dumper($post), 0, 255 )
        : '';                                               # varchar(255)
    ($loadtime) = ( $loadtime =~ /^(\d{1,5}\.?\d{0,2})/ );  # float(5,2)
    my $session_id = $c->sessionid;
    my $user_id = ( $c->user_exists ) ? $c->user->user_id : 0;

    $c->model('DBIC::LogPath')->create(
        {   session_id => $session_id,
            user_id    => $user_id,
            path       => $path,
            get        => $get,
            post       => $post,
            loadtime   => $loadtime,
        }
    );
}

sub log_action {
    my ( $self, $c, $info ) = @_;

    my $user_id = $c->user_exists ? $c->user->user_id : 0;

    $c->model('DBIC::LogAction')->create(
        {   user_id     => $user_id,
            action      => $info->{action} || 'kiss',
            object_type => $info->{object_type} || 'ass',
            object_id   => $info->{object_id} || 0,         # times
            time        => \'NOW()',
            text        => $info->{text} || '',
            forum_id    => $info->{forum_id} || 0,
        }
    );
}

sub log_error {
    my ( $self, $c, $level, $error ) = @_;

    $level ||= 'debug';

    # thin wrapper for Foorum::Log sub error_log
    error_log( $c->model('DBIC'), $level, $error );
}

sub check_c_error {
    my ( $self, $c ) = @_;

    my @error = @{ $c->error };
    return 0 unless ( scalar @error );

    my $error = join( "\n", @error );

    error_log( $c->model('DBIC'), 'fatal', $error );

    $c->stash->{simple_wrapper} = 1;
    $c->stash->{error}          = { msg => $error };
    $c->stash->{template}       = 'simple/error.html';
    $c->error(0);

    return 1;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
