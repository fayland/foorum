#!/usr/bin/perl

use strict;
use warnings;
use Pod::Html;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use File::Next;
use File::Basename;
use File::Path;
use File::Spec;

my $lib_dir = abs_path( File::Spec->catdir( $Bin, '..', '..', 'lib' ) );
my $html_dir = abs_path( File::Spec->catdir( $Bin, '..', '..', 'docs', 'pod' ) );

my $files = File::Next::files($lib_dir);

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.pm$/ );    # only pm

    my $in_file  = $file;
    my $out_file = $in_file;
    $out_file =~ s/(\/|\\)lib(\/|\\)/\/docs\/pod\//is;
    $out_file =~ s/\.pm/\.html/isg;

    my $out_dir = dirname($out_file);
    unless ( -d $out_dir ) {
        mkpath( [$out_dir], 0, 0777 );    ## no critic (ProhibitLeadingZeros)
    }

    eval {
        pod2html( "--infile=$in_file", "--outfile=$out_file",
            "--css=http://search.cpan.org/s/style.css",
        );
    };

    if ($@) {
        print "[FAIL] $in_file fails\n";
    }
}

1;
