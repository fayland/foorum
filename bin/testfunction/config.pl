#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/config/;
use Data::Dumper;

my $config = config();
print Dumper( \$config );

1;
