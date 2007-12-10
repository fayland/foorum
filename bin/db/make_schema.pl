#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin $RealBin/;
use Cwd qw/abs_path/;

use DBIx::Class::Schema::Loader qw| make_schema_at dump_to_dir |;

my $path = abs_path("$RealBin/../../lib");

use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/config/;
my $config = config();

make_schema_at(
    "Foorum::Schema",
    { debug => 1, dump_directory => $path },
    [ $config->{dsn}, $config->{dsn_user}, $config->{dsn_pwd} ]
);


1;