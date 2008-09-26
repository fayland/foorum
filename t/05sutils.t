#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use DBI;
use Foorum::XUtils qw/config/;

# check if database is on
BEGIN {
    my $config = config();
    my $dns    = $config->{dsn};
    my $user   = $config->{dsn_user};
    my $pass   = $config->{dsn_pwd};
    eval {
        my $dbh = DBI->connect( $dns, $user, $pass,
            { RaiseError => 1, PrintError => 1 } )
            or die $DBI::errstr;
    };
    $@ and plan skip_all => "the database $dns can not be connected";
    plan tests => 3;
};

use Foorum::SUtils qw/schema/;

my $schema = schema();
isa_ok( $schema, 'Foorum::Schema',   'schema() ISA Foorum::Schema' );

my @sources = $schema->sources();
ok(grep { $_ eq 'User' } @sources, 'sources contains User');
ok(grep { $_ eq 'Forum' } @sources, 'sources contains Forum');