#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 2;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::TestUtils qw/schema base_path/;
my $schema = schema();

foreach ( 1, 2 ) {
    my $return = $schema->resultset('Star')->del_or_create(
        {   user_id     => 1,
            object_type => 'test',
            object_id   => 1
        }
    );

    my $count = $schema->resultset('Star')->count(
        {   user_id     => 1,
            object_type => 'test',
            object_id   => 1
        }
    );

    if ( $return == 1 ) {
        is( $count, 1, 'star OK' );
    } else {
        is( $count, 0, 'unstar OK' );
    }
}

# cleanup
$schema->resultset('Star')->search(
    {   user_id     => 1,
        object_type => 'test',
        object_id   => 1,
    }
)->delete;

END {

    # Keep Database the same from original
    use File::Copy ();
    my $base_path = base_path();
    File::Copy::copy(
        File::Spec->catfile( $base_path, 't', 'lib', 'Foorum', 'backup.db' ),
        File::Spec->catfile( $base_path, 't', 'lib', 'Foorum', 'test.db' )
    );
}
