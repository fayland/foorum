package Foorum::Scraper::MailMan;

use strict;
use warnings;
use vars qw/$VERSION/;
use HTML::TokeParser::Simple;
use LWP::Simple;
$VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = {};

    return bless $self => $class;
}

sub scraper {
    my ( $self, $url ) = @_;

    my $html = get($url);
    unless ($html) {
        return;
    }

    my $ret = $self->extract($html);
    return $ret;
}

sub extract_from_thread {
    my ( $self, $html ) = @_;

    my $ret;

    my $p = HTML::TokeParser::Simple->new( string => $html );
    while ( my $token = $p->get_token ) {
        if ( my $tag = $token->get_tag ) {
            if ( $tag eq 'li' ) {

                # XXX? TODO
            }
        }
    }

    return $ret;
}

sub extract_from_date {
    my ( $self, $html ) = @_;

}

sub extract_from_message {
    my ( $self, $html ) = @_;

    my $text;
    my $p = HTML::TokeParser::Simple->new( string => $html );
    while ( my $token = $p->get_token ) {
        if ( $token->is_start_tag( 'pre' ) ) {
            $p->{start} = 1;
        } elsif ($p->{start}) {
            $text .= $token->as_is();
        }
        last if ( $token->is_end_tag( 'pre' ) );
    }
    $text = mail_body_to_abstract($text);
    return $text;
}

# directly copied from mailman-archive-to-rss
# http://taint.org/mmrss/
# Thanks, Adam Shand

sub mail_body_to_abstract {
    my $text = shift;
    local ($_);

    # strip quoted text, replace with \002
    # This is tricky, to catch the "> quote blah chopped\nin mail\n" case
    my $newtext      = '';
    my $lastwasquote = 0;
    my $lastwasblank = 0;

    foreach ( split( /^/, $text ) ) {
        s/^<\/I>//gi;

        if (/^\s*$/) {
            $lastwasblank = 1;
            $newtext .= "\n";
            next;
        } else {
            $lastwasblank = 0;
        }

        if (/^\s*\S*\s*(?:>|\&gt;)/i) {
            $lastwasquote = 1;
            $newtext .= "\002";
            next;
        } else {
            if ( $lastwasquote && !$lastwasblank && length($_) < 20 ) { next; }
            $newtext .= $_;
            $lastwasquote = 0;
        }
    }
    $text = $newtext;

    # collapse \002's into 1 [...]
    $text =~ s/\s*\002[\002\s]*/\n\n[...]\n\n/igs;

    # PGP header
    $text =~ s/-----BEGIN PGP SIGNED MESSAGE-----.*?\n\n//gs;

    # MIME crud
    $text =~ s/\n--.+?\n\n//gs;
    $text =~ s/This message is in MIME format.*?\n--.+?\n\n//gs;
    $text =~ s/This is a multipart message in MIME format.*?\n--.+?\n\n//gs;
    $text =~ s/^Content-\S+:.*$//gm;

    # trim sigs etc.
    $text =~ s/\n-- \n.*$//gs;     # trad-style
    $text =~ s/\n_____+.*$//gs;    # Hotmail
    $text =~ s/\n-----.*$//gs;     # catches PGP sigs

    $text;
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
