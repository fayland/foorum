#!/usr/bin/perl -w

use strict;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use DBICx::AutoDoc;

## XXX? TODO

my $ad = DBICx::AutoDoc->new(
    schema => 'Foorum::Schema',
    output => $Bin,
);
$ad->fill_template('html');

1;
