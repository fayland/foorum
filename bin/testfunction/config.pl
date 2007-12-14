#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/config/;
use Data::Dumper;

my $config = config();
print Dumper(\$config);

1;