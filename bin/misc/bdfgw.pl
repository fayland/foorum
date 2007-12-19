#!/usr/bin/perl

######################
# Build Docs From GoogleCode wiki
######################

use strict;
use warnings;
use Text::GooglewikiFormat;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;

my $trunk_dir = abs_path("$Bin/../../../trunk");
my $wiki_dir  = abs_path("$Bin/../../../wiki");
my $project_url = 'http://code.google.com/p/foorum';

my %tags = %Text::GooglewikiFormat::tags;
my @filenames = ('README', 'INSTALL', 'Configure', 'I18N', 'TroubleShooting');

# replace link sub
my $linksub = sub {
    my ($link, $opts)        = @_;
    $opts                  ||= {};

    my $ori_text = $link;
    ($link, my $title)       = Text::GooglewikiFormat::find_link_title( $link, $opts );
    ($link, my $is_relative) = Text::GooglewikiFormat::escape_link( $link, $opts );
    unless ($is_relative) {
        return qq|<a href="$link" rel="nofollow">$title</a>|;
    } elsif (grep { $link eq $_ } @filenames) {
      return qq|<a href="$link\.html">$ori_text</a>|;  
    } else {
      return $ori_text;
    }
};
$tags{link} = $linksub;

# build in trunk/docs dir
foreach my $filename (@filenames) {
    {
        local $/;
        open(FH, "$wiki_dir/$filename\.wiki");
        flock(FH, 1);
        my $string = <FH>;
        close(FH);
        $string =~ s/&/&amp;/gs;
        $string =~ s/>/&gt;/gs;
        $string =~ s/</&lt;/gs;
        my $html = Text::GooglewikiFormat::format($string, \%tags);
        $html = <<HTML;
<link type="text/css" rel="stylesheet" href="http://code.google.com/hosting/css/d_20071112.css" />
<h1>From <a href="$project_url/wiki/$filename">$project_url/wiki/$filename</a></h1>
$html
HTML
        open(FH, ">$trunk_dir/docs/$filename\.html");
        flock(FH, 2);
        print FH $html;
        close(FH);
        print "format $filename OK\n";
        
        # XXX? TODO
        # text to README INSTALL
    }
}