#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    $ENV{TEST_FOORUM} = 1;
}

use Test::More tests => 3;
use DBI;
use Foorum::SUtils qw/schema/;

my $schema = schema();
isa_ok( $schema, 'Foorum::Schema', 'schema() ISA Foorum::Schema' );

my @sources = $schema->sources();
ok( grep { $_ eq 'User' } @sources,  'sources contains User' );
ok( grep { $_ eq 'Forum' } @sources, 'sources contains Forum' );
