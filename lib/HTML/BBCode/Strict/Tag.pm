package HTML::BBCode::Strict::Tag;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

use Carp qw/ croak /;

__PACKAGE__->mk_accessors(
    qw/ name arg isclosed has_closing_tag content tags_can_be_inside
        pattern ignore_all_inside_tags /
);

sub can_be_inside {
    my ( $s, $tag ) = @_;

    croak 'Not a ' . __PACKAGE__ . ' instance'
        unless ref $tag && $tag->isa(__PACKAGE__);

    if ( grep { $tag->name eq $_ } @{ $s->tags_can_be_inside } ) {
        return 1;
    }

    return 0;
}

sub as_html {
    my ($s) = @_;

    if ( ref $s->pattern eq 'CODE' ) {
        if ( $s->content ) {
            return $s->pattern->( $s->content, $s->arg );
        } else {
            if ( $s->has_closing_tag ) {
                return '';
            } else {
                return $s->pattern->( $s->arg );
            }
        }
    } else {
        return $s->pattern;
    }
}

sub as_tag {
    my ($s) = @_;

    if ( $s->isclosed ) {
        return '[/' . $s->name . ']';
    } else {
        if ( $s->arg ) {
            return '[' . $s->name . '=' . $s->arg . ']';
        } else {
            return '[' . $s->name . ']';
        }
    }
}

sub push_content {
    my ( $s, $content ) = @_;

    if ( $s->content ) {
        $s->content( $s->content . $content );
    } else {
        $s->content($content);
    }
}

1;
