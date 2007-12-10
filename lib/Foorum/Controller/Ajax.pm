package Foorum::Controller::Ajax;

use strict;
use warnings;
use base 'Catalyst::Controller';
use YAML::Syck;
use Data::Dumper;

sub auto : Private {
    my ( $self, $c ) = @_;

    # no cache
    $c->res->header(
        'Cache-Control' => 'no-cache, must-revalidate, max-age=0' );
    $c->res->header( 'Pragma' => 'no-cache' );

    return 1;
}

=pod

=item new_message

(Global Site) check if a user get any new message

=cut

sub new_message : Local {
    my ( $self, $c ) = @_;

    $c->stash->{donot_log_path} = 1;

    return $c->res->body(' ') unless ( $c->user_exists );

    my $count = $c->model('DBIC::MessageUnread')
        ->count( { user_id => $c->user->user_id, } );

    if ($count) {
        $c->res->body( "<a href='/message'><span style='color:red'>"
                . $c->localize( "You have new messages ([_1])", $count )
                . "</span></a>" );
    } else {
        return $c->res->body(' ');
    }
}

=pod

=item loadstyle?style=$stylename

(ForumAdmin.pm/style) Load the $stylename.yml under HOME/style, and print the javscript

=cut

sub loadstyle : Local {
    my ( $self, $c ) = @_;

    my $style = $c->req->param('style');
    return unless ($style);
    $style =~ s/\W+/\_/isg;

    my $output;

    my $style_file
        = $c->path_to( 'style', 'system', "$style\.yml" )->stringify;
    return unless ( -e $style_file );

    $style = LoadFile($style_file);

    foreach ( keys %{$style} ) {
        my $background = qq~\$('#$_').style.background = "$style->{$_}";~
            if ( $style->{$_} =~ /^\#/ );
        $output .= <<JAVASCRIPT;
        \$('#$_').value = "$style->{$_}";
        $background
JAVASCRIPT
    }

    $c->res->content_type('text/javascript');
    $c->res->body($output);
}

=pod

=item validate_username

Ajax way to validate the username in Register progress.

=cut

sub validate_username : Local {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');

    my $ERROR = $c->model('Validation')->validate_username( $c, $username );
    return $c->res->body($ERROR) if ($ERROR);

    $c->res->body('OK');
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
