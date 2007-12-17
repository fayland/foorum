package Foorum::Formatter;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK $VERSION/;
@EXPORT_OK = qw/
    filter_format
    /;
$VERSION = '0.01'; # version

use vars qw/$has_text_textile $has_ubb_code $has_text_wiki/;
$has_text_textile = eval "use Text::Textile; 1;";
$has_ubb_code     = eval "use Foorum::Formatter::BBCode; 1;";
$has_text_wiki    = eval "use Text::WikiFormat; 1;";

sub filter_format {
    my ( $text, $params ) = @_;

    my $format = $params->{format};
    if ( $format eq 'textile' and $has_text_textile ) {
        my $formatter = Text::Textile->new();
        $formatter->charset('utf-8');
        $text = $formatter->process($text);
    } elsif ( $format eq 'ubb' and $has_ubb_code ) {
        my $formatter = Foorum::Formatter::BBCode->new(
            {   stripscripts => 1,
                linebreaks   => 1,
            }
        );
        $text = $formatter->parse($text);
    } elsif ( $format eq 'wiki' and $has_text_wiki) {
        $text =~ s/&/&amp;/gs;
        $text =~ s/>/&gt;/gs;
        $text =~ s/</&lt;/gs;
        my %tags = %Text::WikiFormat::tags;
        my %opts = ( extended => 1, absolute_links => 1 );
        $text = Text::WikiFormat::format($text, \%tags, \%opts);
    } else {
        $text =~ s/&/&amp;/gs;   # no_html
        $text =~ s|<|&lt;|gs;
        $text =~ s|>|&gt;|gs;
        $text =~ s|\n|<br />\n|gs;    # linebreaks
    }

    return $text;
}

1;
__END__

=pod

=head1 NAME

Foorum::Formatter - format content for Foorum

=head1 DESCRIPTION

  use Foorum::Formatter qw/filter_format/;
  
  my $text = q~ :inlove: [b]Test[/b] [size=14]dsadsad[/size] [url=http://fayland/]da[/url]~;
  my $html = filter($text, { format => 'ubb' } );
  print $html;
  # <img src="/static/images/bbcode/emot/inlove.gif"> <span style="font-weight:bold">Test</span> <span style="font-size:14px">dsadsad</span> <a href="http://fayland/">da</a>

=head1 SEE ALSO

L<HTML::BBCode>, L<Text::Textile>, L<Text::WikiFormat>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut
