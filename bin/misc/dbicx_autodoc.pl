#!/usr/bin/perl -w

use strict;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use DBICx::AutoDoc;
use Data::Dumper;

my $ad = DBICx::AutoDoc->new(
    schema => 'Foorum::Schema',
    output => "$Bin/../../docs",
);

$ad->include_path("$Bin/autodoc-templates");
$ad->fill_template("AUTODOC.html");

1;