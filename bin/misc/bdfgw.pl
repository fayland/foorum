#!/usr/bin/perl

######################
# Build Docs From GoogleCode wiki
######################

use strict;
use warnings;
use Text::GooglewikiFormat;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use File::Copy;

my $trunk_dir   = abs_path("$Bin/../../../trunk");
my $wiki_dir    = abs_path("$Bin/../../../wiki");
my $project_url = 'http://code.google.com/p/foorum';

my @filenames = (
    'README',          'INSTALL',   'Configure', 'I18N',
    'TroubleShooting', 'AUTHORS',   'RULES',     'HowRSS',
    'Tutorial1',       'Tutorial2', 'Tutorial3', 'Tutorial4',
    'Tutorial5',
);

my %tags = %Text::GooglewikiFormat::tags;

# replace link sub
my $linksub = sub {
    my ( $link, $opts ) = @_;
    $opts ||= {};

    my $ori_text = $link;
    ( $link, my $title ) = Text::GooglewikiFormat::find_link_title( $link, $opts );
    ( $link, my $is_relative ) = Text::GooglewikiFormat::escape_link( $link, $opts );
    unless ($is_relative) {
        return qq|<a href="$link" rel="nofollow">$title</a>|;
    } elsif (
        grep {
            $link eq $_
        } @filenames
        ) {
        return qq|<a href="$link\.html">$ori_text</a>|;
    } else {
        return $ori_text;
    }
};
$tags{link} = $linksub;

my $indexpage;

# build in trunk/docs dir
foreach my $filename (@filenames) {
    {
        local $/;
        open( my $fh, '<', "$wiki_dir/$filename\.wiki" );
        flock( $fh, 1 );
        my $string = <$fh>;
        close($fh);
        $string =~ s/&/&amp;/gs;
        $string =~ s/>/&gt;/gs;
        $string =~ s/</&lt;/gs;
        my $html = Text::GooglewikiFormat::format( $string, \%tags );
        buildhtml( $filename, $html );

        $indexpage .= qq~<li><a href="$filename\.html">$filename</a></li>~;

        # XXX? TODO
        # text to README INSTALL AUTHOR
        if ( $filename eq 'AUTHORS' ) {
            copy( "$wiki_dir/$filename\.wiki", "$trunk_dir/$filename" );
        }
    }
}

buildhtml( 'index', qq~<ul>$indexpage</ul>~ );

sub buildhtml {
    my ( $filename, $html ) = @_;

    my $wiki_url = "$project_url/wiki/$filename";
    $wiki_url = 'http://code.google.com/p/foorum/w/list'
        if ( $filename eq 'index' );

    $html = <<HTML;
<html>
<head>
<title>$filename</title>
<link type="text/css" rel="stylesheet" href="static/d_20071112.css" />
<!--[if IE]>
<link type="text/css" rel="stylesheet" href="static/d_ie.css" />
<![endif]--> 
</head>
<body class="t6">
<div id="wikicontent">
$html
</div>
<h1>WHERE TO GO NEXT</h1>
<p>Get the lastest version from <a href="$wiki_url">$wiki_url</a></p>
<script src="static/prettify.js"></script>
<script>
 prettyPrint();
</script>
</body>
</html>
HTML
    open( my $fh, '>', "$trunk_dir/docs/$filename\.html" );
    flock( $fh, 2 );
    print $fh $html;
    close($fh);
    print "format $filename OK\n";
}
