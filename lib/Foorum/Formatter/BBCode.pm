package Foorum::Formatter::BBCode;

use strict;
use warnings;
use base 'HTML::BBCode'; # > 2.00
use Class::C3; # for next::method();

our @bbcode_tags = qw(code quote b u i color size list url email img font align flash music);

sub new {
    my $self = (shift)->next::method(@_);

    $self->{options}->{html_tags}->{font} = '<span style="font-family: %s">%s</span>';
    $self->{options}->{html_tags}->{align} = '<div style="text-align: %s">%s</div>';
    $self->{options}->{html_tags}->{flash} = q!<div class='flash'><embed src='%s' width='480' height='360'></embed></div>!;
    
    return $self;
}

sub parse {
    my $self = shift;
    
    my $html = $self->next::method(@_);
    
    # emot
    return $html unless ( $html =~ /\:\w{2,9}\:/s );
    my @emot_icon = (
        'wink',     'sad',      'biggrin', 'cheesy',
        'confused', 'cool',     'angry',   'sads',
        'smile',    'smiled',   'unhappy', 'dozingoff',
        'blink',    'blush',    'crazy',   'cry',
        'bigsmile', 'inlove',   'notify',  'shifty',
        'sick',     'sleeping', 'sneaky2', 'tounge',
        'unsure',   'wacko',    'why',     'wow',
        'mad',      'Oo'
    );
    my $emot_url = '/static/images/bbcode/emot';
    foreach my $em (@emot_icon) {
        next unless ( $html =~ /\:$em\:/s );
        $html =~ s/\:$em\:/\<img src=\"$emot_url\/$em.gif\"\>/sg;
        last unless ( $html =~ /\:\w{2,9}\:/s );
    }
    $self->{html} = $html;

    return $html;
}

sub _do_BB {
    my ($self, @buf) = @_;

    # ours come first
    my ($tag, $attr);
    my $html;
    
    # Get the opening tag
    my $open = pop(@buf); 
    # We prefer to read in non-reverse way
    @buf = reverse @buf;
    # Closing tag is kinda useless, pop it
    pop(@buf);
    # Rest should be content;
    my $content = join(' ', @buf);
    
    # What are we dealing with anyway? Any attributes maybe?
    if($open =~ /\[([^=\]]+)=?([^\]]+)?]/) {
        $tag  = $1;
        $attr = $2;
    }
    
    if ( $tag eq 'music' ) {
        # patch for music
        if ( $content =~ /\.(ram|rmm|mp3|mp2|mpa|ra|mpga)$/ ) {
            $html
                = qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$content" 
controls="StatusBar,ControlPanel" width='320' height='70' border='0' autostart='flase'></embed></div>!;
        } elsif ( $content =~ /\.(rm|mpg|mpv|mpeg|dat)$/ ) {
            $html
                = qq!<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="$content" 
controls="ImageWindow,StatusBar,ControlPanel" width='352' height='288' border='0' autostart='flase'></embed></div>!;
        } elsif ( $content =~ /\.(wma|mpa)$/ ) {
            $html
                = qq!<div><embed type="application/x-mplayer2" pluginspage="http://www.microsoft.com/Windows/Downloads/Contents/Products/MediaPlayer/" src="$content" name="realradio" showcontrols='1' ShowDisplay='0' ShowStatusBar='1' width='480' height='70' autostart='0'></embed></div>!;
        } elsif ( $content =~ /\.(asf|asx|avi|wmv)$/ ) {
            $html
                = qq!<div><object id="videowindow1" width="480" height="330" classid="CLSID:6BF52A52-394A-11D3-B153-00C04F79FAA6"><param NAME="URL" value="$content"><param name="AUTOSTART" value="0"></object></div>!;
        }
        
        return $html;
    } elsif ($tag eq 'size') {
        $attr = 8  if ( $attr < 8 ); # validation
        $attr = 16 if ( $attr > 16 );
        $html = sprintf( $self->{options}->{html_tags}->{size}, $attr,
            $content );
        return $html;
    }
    
    # go default
    return (shift)->next::method(@_);
}

1;
