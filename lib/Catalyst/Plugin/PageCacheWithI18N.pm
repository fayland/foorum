package Catalyst::Plugin::PageCacheWithI18N;

use strict;
use warnings;
use Class::C3;
use vars qw/$VERSION/;
$VERSION = '0.01';
use base qw/Catalyst::Plugin::PageCache/;

sub _get_page_cache_key {
    my ($c) = @_;

    my $key = $c->next::method(@_);
    my $lang = $c->req->cookie('lang')->value if ( $c->req->cookie('lang') );
    $lang ||= $c->user->lang if ( $c->user_exists );
    $lang ||= $c->config->{default_lang};
    if ( my $set_lang = $c->req->param('lang') ) {
        $set_lang =~ s/\W+//isg;
        if ( length($set_lang) == 2 ) {
            $lang = $set_lang;
        }
    }
    $key .= '#' . $lang if ($lang);
    return $key;
}

1;
