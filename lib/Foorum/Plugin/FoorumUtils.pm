package Foorum::Plugin::FoorumUtils;

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
        return qq~<script type="text/javascript" src="$js_dir/$url"></script>\n~;
    } elsif ( $url =~ /\.css$/i ) {
        my $static_dir = $c->config->{dir}->{static};
        return
            qq~<link rel="stylesheet" href="$static_dir/css/$url" type="text/css" />\n~;
    }
}

1;
__END__

=pod

=head1 NAME

Foorum::Plugin::FoorumUtils - pollute $c by Foorum

=head1 FUNCTIONS

=over 4

=item load_once

Multi-times [% c.load_once('jquery.js') %] would only write one script tag in TT.

It is a trick for INCLUDE tt.html may call the same script src many times.

so does css. [% c.load_once('default.css') %]

We insert before the 'jquery.js' with [% c.config.dir.js %] and the 'default.css' with [% c.config.dir.static %]/css

=back

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
