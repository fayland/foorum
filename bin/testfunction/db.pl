#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::SUtils qw/schema/;

my $schema = schema();

# show the model classes available
my @sources = $schema->sources();
print 'found schema model sources :-  ' . join( ", ", @sources ) . "\n";

1;
