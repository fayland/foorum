#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/schema/;

my $schema = schema();

my $count = $schema->resultset('User')->count();

print $count;

1;