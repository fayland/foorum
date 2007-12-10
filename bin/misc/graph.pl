#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use GraphViz::ISA;
use Foorum;

my $p = Foorum->new;

my $g1 = GraphViz::ISA->new($p);
open(FH, '>foorum.png');
binmode(FH);
print FH $g1->as_png;
close(FH);
  
print 'OK';