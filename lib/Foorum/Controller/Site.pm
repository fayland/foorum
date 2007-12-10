package Foorum::Controller::Site;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Formatter qw/filter_format/;
use Data::Dumper;

sub recent : Local {
    my ( $slef, $c, $recent_type ) = @_;

    my $rss      = ( $c->req->path =~ /\/rss(\/|$)/ ) ? 1 : 0; # /site/recent/rss

    my @extra_cols;
    my $url_prefix;
    if ( $recent_type eq 'elite' ) {
        @extra_cols = ( 'elite', 1 );
        $url_prefix = '/site/recent/elite';
    } else {
        $recent_type = 'site';
        $url_prefix  = '/site/recent';
    }

    my $page = get_page_from_url( $c->req->path );
    my $rs   = $c->model('DBIC::Topic')->search(
        {   'forum.policy' => 'public',
            'me.status' => { '!=', 'banned' },
            @extra_cols,
        },
        {   order_by => 'last_update_date desc',
            prefetch => [ 'author', 'last_updator', 'forum' ],
            join     => [qw/forum/],
            rows     => 20,
            page     => $page,
        }
    );

    $c->stash(
        {
            recent_type => $recent_type,
            url_prefix  => $url_prefix,
        }
    );

    my @topics = $rs->all;
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
        
        $c->cache_page('600');
        $c->stash->{template} = 'site/recent.rss.html';
    } else {
        $c->cache_page('300');
        $c->stash(
            {   template    => 'site/recent.html',
                pager       => $rs->pager,
                topics      => \@topics,
            }
        );
    }
}

sub online : Local {
    my ( $self, $c, undef, $forum_code ) = @_;

    $c->cache_page('300');

    my ( $results, $pager )
        = $c->model('Online')->get_data( $c, $forum_code );

    $c->stash(
        {   results  => $results,
            pager    => $pager,
            template => 'site/online.html',
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
