package Foorum::Formatter;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK $has_text_textile $has_ubb_code $VERSION/;
@EXPORT_OK = qw/
    filter_format
    /;
$VERSION = '0.01'; # version
$has_text_textile = eval "use Text::Textile; 1;";
$has_ubb_code     = eval "use Foorum::Formatter::BBCode; 1;";

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
    } else {
        $text =~ s|<|&lt;|gs;         # no_html
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

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut
