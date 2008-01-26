package HTML::BBCode::Strict;

use warnings;
use strict;

use base 'Class::Accessor::Fast';

use Class::C3;

use HTML::BBCode::Strict::Tag;

__PACKAGE__->mk_accessors(qw/ conf tags iseof current_tag text content bbcode error /);

=head1 NAME

HTML::BBCode::Strict - recursive BBCode parser with strict rules.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $parser = HTML::BBCode::Strict->new;

    my $bbcode = '[i]italic[/i]';

    my $html = $parser->parse( $bbcode );

And you get

    <p><i>italic</i></p>

Restricting some tags

    my $parser = HTML::BBCode::Strict->new( { deny => [ qw/ img url / ] } );

Providing your own tags

    my $parser = HTML::BBCode::Strict->new(
        undef,
        {
            youtube      => has_closing_tag => 1,
            arg_required => 1,
            pattern      => sub {
                qq#<object width="425" height="355">
                       <param name="movie"
                           value="http://www.youtube.com/v/$_[0]"></param>
                       <param name="wmode" value="transparent"></param>
                       <embed src="http://www.youtube.com/v/$_[0]"
                           type="application/x-shockwave-flash"
                           wmode="transparent" width="425" height="355">
                       </embed>
                   </object>#
              }
        }
    );

And you can use it like this

    [youtube]youtube-id[/youtube]

=head1 DESCRIPTION

This is a recursive BBCode parser with strict rules, what means that is will not
allow wrong bbcode, it will set appropriate error and retun undef.

All markup that is described on http://wikipedia.org/wiki/BBCode is supported
with some extensions though. Please, read more in SYNTAX section.

All the tags are described by a tags hash that can be merged with your tags.

=head1 OPTIONS

deny, allow... TODO

=head1 TAG OPTIONS

Tag 'b' is described as

    'b' => {
        tags_can_be_inside => [ qw/ i u s / ],
        has_closing_tag    => 1,
        pattern            => sub { "<b>$_[0]</b>" }
    }

That means

    Tags [i], [u] and [s] can be inside [b] tag. It has a required closing tag
    [/b] and on deflation calls anonymous subroutine with a first parameter as
    text inside of it.

All options

    tags_can_be_inside     - array of tags that can be inside
    has_closing_tag        - does a tag require a closing one
    pattern                - if it is a sub, it is called with a first argument as a
                             text, and second as a parameter; otherwise it is
                             used as a string
    arg_required           - if it is defined and is true - tag argument is
                             required;
                             if it is defined and is false - argument is not
                             required;
                             if it is not defined - setting argument on this tag
                             will cause an error
    ignore_all_inside_tags - ignore all tags except of a closing one (used
                             for [code])

=head1 SYNTAX

Paragraphs are created when there are more then two newlines. No brs! This way
I can have a resizable website. That's what HTML is for.

TODO

=head1 METHODS

=cut

our $default_tags = {
    'b' => {
        tags_can_be_inside => [qw/ i u s /],
        has_closing_tag    => 1,
        pattern            => sub {"<b>$_[0]</b>"}
    },
    'i' => {
        tags_can_be_inside => [qw/ b u s /],
        has_closing_tag    => 1,
        pattern            => sub {
            "<i>$_[0]</i>";
            }
    },
    'u' => {
        tags_can_be_inside => [qw/ b i s /],
        has_closing_tag    => 1,
        pattern            => sub {
            qq#<span style="text-decoration:underline">$_[0]</span>#;
            }
    },
    's' => {
        tags_can_be_inside => [qw/ b u i /],
        has_closing_tag    => 1,
        pattern            => sub {
            "<s>$_[0]</s>";
            }
    },
    'color' => {
        tags_can_be_inside => [qw/ b u i s /],
        has_closing_tag    => 1,
        arg_required       => 1,
        pattern            => sub {
            qq#<span class="color:$_[1]">$_[0]</span>#;
            }
    },
    'hr'  => { pattern => '<hr />' },
    'url' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ img /],
        arg_required       => 0,
        pattern            => sub {
            if ( $_[1] ) {
                qq#<a href="$_[1]">$_[0]</a>#;
            } else {
                qq#<a href="$_[0]">$_[0]</a>#;
            }
            }
    },
    'img' => {
        has_closing_tag => 1,
        arg_required    => 0,
        pattern         => sub {
            qq#<img src="$_[0]" alt="" />#;
            }
    },
    'code' => {
        has_closing_tag        => 1,
        ignore_all_inside_tags => 1,
        pattern                => sub {
            qq#<pre><code>$_[0]</code></pre>#;
            }
    },
    'left' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        pattern            => sub {
            qq#<div style="text-align:left">$_[0]</div>#;
            }
    },
    'center' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        pattern            => sub {
            qq#<div style="text-align:center">$_[0]</div>#;
            }
    },
    'right' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        pattern            => sub {
            qq#<div style="text-align:right">$_[0]</div>#;
            }
    },
    'float' => {
        has_closing_tag    => 1,
        arg_required       => 1,
        tags_can_be_inside => [qw/ b i s u img /],
        pattern            => sub {
            if ( $_[1] eq 'left' ) {
                qq#<div style="float:left">$_[0]</div>#;
            } elsif ( $_[1] eq 'right' ) {
                qq#<div style="float:right">$_[0]</div>#;
            }
            }
    },
    'clear' => {
        pattern => sub {
            qq#<div style="clear:both">$_[0]</div>#;
            }
    },
    'sub' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        pattern            => sub {
            qq#<sub>$_[0]</sub>#;
            }
    },
    'sup' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        pattern            => sub {
            qq#<sup>$_[0]</sup>#;
            }
    },
    'abbr' => {
        has_closing_tag => 1,
        arg_required    => 1,
        pattern         => sub {
            qq#<abbr title="$_[1]">$_[0]</abbr>#;
            }
    },
    'acronym' => {
        has_closing_tag => 1,
        arg_required    => 1,
        pattern         => sub {
            qq#<acronym title="$_[1]">$_[0]</acronym>#;
            }
    },
    'quote' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ b i s u /],
        arg_required       => 0,
        pattern            => sub {
            if ( $_[1] ) {
                qq#<blockquote>$_[1]:<br />$_[0]</blockquote>#;
            } else {
                qq#<blockquote>$_[0]</blockquote>#;
            }
            }
    },
    'list' => {
        has_closing_tag    => 1,
        tags_can_be_inside => [qw/ * b i s u /],
        arg_required       => 0,
        pattern            => sub {
            $_[0] =~ s/<li>(.*?)(?=\n?<li>|$)/<li>$1<\/li>/osg;

            if ( !$_[1] ) {
                qq#<ul>$_[0]</ul>#;
            } elsif ( $_[1] eq '1' ) {
                qq#<ol>$_[0]</ol>#;
            } elsif ( $_[1] eq 'a' ) {
                qq#<ol style="list-style-type:upper-alpha;">$_[0]</ol>#;
            } elsif ( $_[1] eq 'i' ) {
                qq#<ol style="list-style-type:upper-roman;">$_[0]</ol>#;
            }
        },
    },
    '*' => { pattern => '<li>' }
};

sub new {
    my ( $class, $conf, $tags ) = @_;

    $conf ||= {};

    my $merched_tags = _merge_hashes( $default_tags, $tags );

    return bless {
        conf => $conf,
        tags => $merched_tags
    }, $class;
}

sub preprocess {
    my ($s) = @_;

    my $bbcode = $s->bbcode;

    $bbcode =~ s/&/&amp;/gos;
    $bbcode =~ s/</&lt;/gos;
    $bbcode =~ s/>/&gt;/gos;

    $s->bbcode($bbcode);
}

sub postprocess {
    my ($s) = @_;

    my $html = $s->content;

    $html =~ s/^\s+//os;
    $html =~ s/\s+$//os;

    $s->content( '<p>' . $html . '</p>' );
}

sub parse {
    my ( $s, $bbcode ) = @_;

    $s->bbcode($bbcode);
    $s->content('');
    $s->iseof(0);
    $s->error('');

    $s->check_config();

    $s->preprocess();

    $s->get_next_token();

    while ( !$s->iseof && !$s->error ) {
        $s->parse_start();

        last if $s->error;

        if ( $s->text ) {
            my $text = $s->text;

            # some magic from Template::Plugin::PwithBR
            $text =~ s/\x0D\x0A/\n/g;
            $text =~ tr/\x0D\x0A/\n\n/;
            $text =~ s/(?:\r?\n){2,}/<\/p><p>/gs;
            $s->push_content($text);
        } else {
            $s->push_content( $s->current_tag->as_html );
        }

        $s->get_next_token();
    }

    unless ( $s->error ) {
        $s->postprocess();
        return $s->content;
    } else {
        return undef;
    }
}

sub check_config {
}

sub push_content {
    my ( $s, $content ) = @_;

    if ( $s->content ) {
        $s->content( $s->content . $content );
    } else {
        $s->content($content);
    }
}

sub parse_start {
    my ($s) = @_;

    return if $s->error;

    if ( $s->text ) {
    } elsif ( $s->current_tag && !$s->current_tag->isclosed ) {
        if ( $s->current_tag->has_closing_tag ) {
            my $tag = $s->current_tag;

            $s->get_next_token();

            if ( $s->iseof ) {
                $s->error('Unexpected end of file');
                return;
            }

            if (   $s->text
                || $tag->ignore_all_inside_tags
                || $tag->can_be_inside( $s->current_tag )
                || (   $s->current_tag->isclosed
                    && $s->current_tag->name eq $tag->name )
                ) {
                $s->parse_end($tag);
                $s->current_tag($tag);
            } else {
                $s->error('Tag '
                        . $s->current_tag->name
                        . ' cannot be inside tag '
                        . $tag->name );
            }
        }
    } else {
        $s->error( 'Unexpected closing tag: ' . $s->current_tag->as_tag );
    }
}

sub parse_end {
    my ( $s, $end ) = @_;

    return if $s->error;

    unless ( $end->ignore_all_inside_tags ) {
        while (
            $s->text
            || (   $s->current_tag
                && !$s->current_tag->isclosed
                && $s->current_tag->name ne $end->name )
            ) {
            if ( $s->text ) {
                $end->push_content( $s->text );

                $s->get_next_token();
            } else {
                my $tag = $s->current_tag;

                if ( $tag->isclosed ) {
                    $s->error( 'Unexpected closing tag: ' . $tag->name );
                } else {
                    if ( $end->can_be_inside($tag) ) {
                        if ( $s->current_tag->has_closing_tag ) {
                            $s->parse_start();
                            return if $s->error;
                            $end->push_content( $s->text || $s->current_tag->as_html );
                            $s->get_next_token();
                        } else {
                            $end->push_content( $s->text || $s->current_tag->as_html );
                            $s->get_next_token();
                        }
                    } else {
                        $s->error('Tag '
                                . $s->current_tag->name
                                . ' cannot be inside tag '
                                . $end->name );
                    }
                }
            }
        }
    } else {
        while ( !$s->iseof && !$s->error ) {
            if ( $s->text ) {
                $end->push_content( $s->text );
            } elsif ( $s->current_tag->isclosed
                && $s->current_tag->name eq $end->name ) {
                return;
            } else {
                $end->push_content( $s->current_tag->as_tag );
            }

            $s->get_next_token();
        }
    }
}

sub get_next_token {
    my ($s) = @_;

    my $bbcode = $s->bbcode;

    $s->current_tag('');
    $s->text('');

    if ( !$bbcode ) {
        $s->iseof(1);
    } else {
        if ( $bbcode =~ s/^\[(\/)?([a-z\*]+)(=(.+?))?\]//so ) {
            my $tag;
            if ( ( my $name ) = grep { $_ eq $2 } keys %{ $s->tags } ) {
                $tag = $s->tags->{$name};

                if ( $1 && !$tag->{has_closing_tag} ) {
                    $s->error("Tag '$2' doesn't support closing");
                } elsif ( !$1 && $tag->{arg_required} && !$4 ) {
                    $s->error("Tag '$2' requires an argument");
                } elsif ( !$1 && $4 && !defined $tag->{arg_required} ) {
                    $s->error("Tag '$2' doesn't have argument");
                } else {
                    $s->current_tag(
                        HTML::BBCode::Strict::Tag->new(
                            {   name     => $2,
                                isclosed => $1 ? 1 : 0,
                                arg => $4 || '',
                                %$tag
                            }
                        )
                    );
                }
            } else {
                $s->error( 'Wrong tag: ' . $2 );
            }
        } elsif ( $bbcode =~ s/^(.+?)(?=\[|$)//so ) {
            $s->text($1);
        }
    }

    if ( $s->current_tag || $s->text ) {
        $s->bbcode($bbcode);
    }
}

# from Catalyst::Utils
sub _merge_hashes {
    my ( $lefthash, $righthash ) = @_;

    return $lefthash unless defined $righthash;

    my %merged = %$lefthash;
    for my $key ( keys %$righthash ) {
        my $right_ref = ( ref $righthash->{$key} || '' ) eq 'HASH';
        my $left_ref
            = ( ( exists $lefthash->{$key} && ref $lefthash->{$key} ) || '' ) eq 'HASH';

        if ( $right_ref and $left_ref ) {
            $merged{$key} = _merge_hashes( $lefthash->{$key}, $righthash->{$key} );
        } else {
            $merged{$key} = $righthash->{$key};
        }
    }

    return \%merged;
}

=head1 AUTHOR

Viacheslav Tikhanovskii, C<< <viacheslav.t at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-bbcode-strict at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-BBCode-Strict>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::BBCode::Strict


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-BBCode-Strict>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-BBCode-Strict>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-BBCode-Strict>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-BBCode-Strict>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Viacheslav Tikhanovskii, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of HTML::BBCode::Strict
