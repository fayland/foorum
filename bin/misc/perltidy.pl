#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Perl::Tidy;
use File::Next;
use File::Copy;

my $path = abs_path("$RealBin/../..");

my $files = File::Next::files( $path );

while ( defined ( my $file = $files->() ) ) {
    next if ( $file !~ /\.(p[ml]|t)$/ );            # only .pm .pl .t
    next if ( $file =~ /perltidy/ );                # skip this file
    next if ( $file =~ /Schema\.pm$/ );             # skip this file
    next if ( $file =~ /(\/|\\)Schema(\/|\\)/ );    # skip Schema dir and Schema.pm

    print "$file\n";

    my $tidyfile = $file . '.tdy';
    Perl::Tidy::perltidy(
        source            => $file,
        destination       => $tidyfile,
        perltidyrc        => "$RealBin/.perltidyrc",
    );
    move($tidyfile, $file);
}

exit;

1;