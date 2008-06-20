package Foorum::Controller::Utils;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub captcha : Global {
    my ( $self, $c ) = @_;
    $c->create_captcha();
}

sub print_message : Private {
    my ( $self, $c, $msg ) = @_;

    if ( ref($msg) ne 'HASH' ) {
        $msg = { msg => $msg };
    }

    $c->stash->{message}  = $msg;
    $c->stash->{template} = 'simple/message.html';
}

sub print_error : Private {
    my ( $self, $c, $error ) = @_;

    if ( ref($error) ne 'HASH' ) {
        $error = { msg => $error };
    }

    $c->stash->{error}    = $error;
    $c->stash->{template} = 'simple/error.html';
}

sub clear_when_topic_changes : Private {
    my ( $self, $c, $forum ) = @_;

    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};
    $c->clear_cached_page('/forum');
    $c->clear_cached_page("/forum/$forum_id");
    $c->clear_cached_page("/forum/$forum_code") if ($forum_code);
    $c->clear_cached_page("/forum/$forum_id/rss");
    $c->clear_cached_page("/forum/$forum_code/rss") if ($forum_code);
    $c->clear_cached_page('/site/recent');
    $c->clear_cached_page('/site/recent/rss');
    clear_when_topic_elite( $self, $c, $forum );
}

sub clear_when_topic_elite : Private {
    my ( $self, $c, $forum ) = @_;

    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};
    $c->clear_cached_page("/forum/$forum_id/elite");
    $c->clear_cached_page("/forum/$forum_code/elite") if ($forum_code);
    $c->clear_cached_page('/site/recent/elite');
    $c->clear_cached_page('/site/recent/elite/rss');
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
