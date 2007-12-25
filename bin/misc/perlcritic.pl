#!/usr/bin/perl -w

use strict;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Perl::Critic;
use File::Next;

my $path = abs_path("$RealBin/../..");

my $files  = File::Next::files($path);
my $critic = Perl::Critic->new();

open( my $fh, '>', 'critic.txt' );
flock( $fh, 2 );

while ( defined( my $file = $files->() ) ) {
    next if ( $file !~ /\.p[ml]$/ );             # only .pm .pl
    next if ( $file =~ /Schema\.pm$/ );          # skip this file
    next if ( $file =~ /(\/|\\)Schema(\/|\\)/ ); # skip Schema dir and Schema.pm

    print "$file\n";

    my @violations = $critic->critique($file);
    $file =~ s/^((.*?)trunk(\\|\/))//isg;
    unless ( scalar @violations ) {
        print $fh "$file source OK\n";
    } else {
        foreach (@violations) {
            print $fh "$file: $_";
        }
    }
}
close($fh);

exit;

1;
