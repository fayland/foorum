#!/usr/bin/perl -w

use strict;
use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );

use GraphViz::ISA;
use Foorum;

my $p = Foorum->new;

my $g1 = GraphViz::ISA->new($p);
open( my $fh, '>', 'foorum.png' );
binmode($fh);
print $fh $g1->as_png;
close($fh);

print 'OK';
