package Catalyst::Plugin::FoorumUtils;

use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.01';

sub load_once {
    my ( $c, $url ) = @_;

    # do not load twice
    return
        if ($c->stash->{__load_once_in_tt}
        and $c->stash->{__load_once_in_tt}->{$url} );
    $c->stash->{__load_once_in_tt}->{$url} = 1;

    if ( $url =~ /\.js$/i ) {
        my $js_dir = $c->config->{dir}->{js};
        return
            qq~<script type="text/javascript" src="$js_dir/$url"></script>\n~;
    } elsif ( $url =~ /\.css$/i ) {
        my $static_dir = $c->config->{dir}->{static};
        return
            qq~<link rel="stylesheet" href="$static_dir/css/$url" type="text/css" />\n~;
    }
}

1;
