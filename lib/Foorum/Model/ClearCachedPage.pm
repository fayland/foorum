package Foorum::Model::ClearCachedPage;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub clear_when_topic_changes {
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

sub clear_when_topic_elite {
    my ( $self, $c, $forum ) = @_;

    my $forum_id   = $forum->{forum_id};
    my $forum_code = $forum->{forum_code};
    $c->clear_cached_page("/forum/$forum_id/elite");
    $c->clear_cached_page("/forum/$forum_code/elite") if ($forum_code);
    $c->clear_cached_page('/site/recent/elite');
    $c->clear_cached_page('/site/recent/elite/rss');
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
