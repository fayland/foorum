#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin $RealBin/;
use File::Spec;
use Cwd qw/abs_path/;

use DBIx::Class::Schema::Loader qw| make_schema_at dump_to_dir |;

my $path = abs_path( File::Spec->catdir( $RealBin, '..', '..', 'lib' ) );

use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Foorum::XUtils qw/config/;
my $config = config();

make_schema_at(
    "Foorum::Schema",
    { debug => 1, dump_directory => $path },
    [ $config->{dsn}, $config->{dsn_user}, $config->{dsn_pwd} ]
);

1;
