#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/schema/;
use Data::Dumper;

my $schema = schema();
print Dumper(\$schema);

1;