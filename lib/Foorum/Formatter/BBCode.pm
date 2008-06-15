package Foorum::Formatter::BBCode;

use strict;
use warnings;

use Foorum::Version; our $VERSION = $Foorum::VERSION;

#use base 'HTML::BBCode::Strict';
#use Class::C3;              # for next::method();
use HTML::BBCode::Strict;

sub new {
    my ( $class, $conf, $tags ) = @_;

    # our tags
    $tags->{size} = {
        has_closing_tag    => 1,
        arg_required       => 1,
        tags_can_be_inside => [qw/ b u i s color /],
        pattern            => sub {
            qq#<span style="font-size: $_[1]pt;">$_[0]</span>#;
            }
    };
    $tags->{font} = {
        has_closing_tag    => 1,
        arg_required       => 1,
        tags_can_be_inside => [qw/ b u i s color /],
        pattern            => sub {
            qq#<span style="font-family: $_[1];">$_[0]</span>#;
            }
    };
    $tags->{flash} = {
        has_closing_tag        => 1,
        arg_required           => 0,
        ignore_all_inside_tags => 1,
        pattern                => sub {
            qq#<div class='flash'><embed src='$_[0]' width='480' height='360'></embed></div>#;
            }
    };
    $tags->{music} = {
        has_closing_tag        => 1,
        arg_required           => 0,
        ignore_all_inside_tags => 1,
        pattern                => sub {
            my $embed_src = $_[0];
            if ( $embed_src =~ /\.(ram|rmm|mp3|mp2|mpa|ra|mpga)$/ ) {
                return
                    qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$embed_src" 
controls="StatusBar,ControlPanel" width='320' height='70' border='0' autostart='flase'></embed></div>!;
            } elsif ( $embed_src =~ /\.(rm|mpg|mpv|mpeg|dat)$/ ) {
                return
                    qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$embed_src" 
controls="ImageWindow,StatusBar,ControlPanel" width='352' height='288' border='0' autostart='flase'></embed></div>!;
            } elsif ( $embed_src =~ /\.(wma|mpa)$/ ) {
                return
                    qq!<div><embed type="application/x-mplayer2" pluginspage="http://www.microsoft.com/Windows/Downloads/Contents/Products/MediaPlayer/" src="$embed_src" name="realradio" showcontrols='1' ShowDisplay='0' ShowStatusBar='1' width='480' height='70' autostart='0'></embed></div>!;
            } elsif ( $embed_src =~ /\.(asf|asx|avi|wmv)$/ ) {
                return
                    qq!<div><object id="videowindow1" width="480" height="330" classid="CLSID:6BF52A52-394A-11D3-B153-00C04F79FAA6"><param NAME="URL" value="$embed_src"><param name="AUTOSTART" value="0"></object></div>!;
            }
            }
    };
    $tags->{video} = {
        has_closing_tag        => 1,
        arg_required           => 0,
        ignore_all_inside_tags => 1,
        pattern                => sub {
            my $embed_src = $_[0];
            if ( $embed_src =~ /youtube\.com/ ) {
                qq#<object width="425" height="355">
                       <param name="movie"
                           value="$embed_src"></param>
                       <param name="wmode" value="transparent"></param>
                       <embed src="$embed_src"
                           type="application/x-shockwave-flash"
                           wmode="transparent" width="425" height="355">
                       </embed>
                   </object>#;
            } else {
                return $embed_src;
            }
            }
    };

    #my $self = $class->next::method($conf, $tags);
    my $self = HTML::BBCode::Strict->new( $conf, $tags );

    return $self;
}

1;
