package Foorum::Model::Validation;

use strict;
use warnings;
use base 'Catalyst::Model';
use Email::Valid::Loose;
use Data::Dumper;

sub validate_username {
    my ( $self, $c, $username ) = @_;

    return 'LENGTH' if ( length($username) < 6 or length($username) > 20 );

    for ($username) {
        return 'HAS_BLANK' if (/\s/);
        return 'HAS_SPECAIL_CHAR' unless (/^[A-Za-z0-9\_]+$/s);
    }

    # username_reserved
    my @reserved
        = $c->model('FilterWord')->get_data( $c, 'username_reserved' );
    return 'HAS_RESERVED' if ( grep { lc($username) eq lc($_) } @reserved );

    # unique
    my $cnt = $c->model('DBIC::User')->count( { username => $username, } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

sub validate_email {
    my ( $self, $c, $email ) = @_;

    return 'LENGTH' if ( length($email) < 5 or length($email) > 64 );

    return 'EMAIL_LOOSE' unless ( Email::Valid::Loose->address($email) );

    # unique
    my $cnt = $c->model('DBIC::User')->count( { email => $email, } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

sub validate_forum_code {
    my ( $self, $c, $forum_code ) = @_;

    return 'LENGTH'
        if ( length($forum_code) < 6 or length($forum_code) > 20 );

    for ($forum_code) {
        return 'HAS_BLANK' if (/\s/);
        return 'REGEX' unless (/[A-Za-z]+/s);
        return 'REGEX' unless (/^[A-Za-z0-9\_]+$/s);
    }

    # forum_code_reserved
    my @reserved
        = $c->model('FilterWord')->get_data( $c, 'forum_code_reserved' );
    return 'HAS_RESERVED' if ( grep { lc($forum_code) eq lc($_) } @reserved );

    # unique
    my $cnt
        = $c->model('DBIC::Forum')->count( { forum_code => $forum_code, } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

sub validate_comment {
    my ( $self, $c ) = @_;

    my $title = $c->req->param('title');
    my $text  = $c->req->param('text');
    unless ( $title and length($title) < 80 ) {
        $c->detach( '/print_error', ['ERROR_TITLE_LENGTH'] );
    } else {
        $c->model('FilterWord')->has_bad_word( $c, $title );
    }
    unless ($text) {
        $c->detach( '/print_error', ['ERROR_TEXT_REQUIRED'] );
    } else {
        $c->model('FilterWord')->has_bad_word( $c, $text );
    }
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
