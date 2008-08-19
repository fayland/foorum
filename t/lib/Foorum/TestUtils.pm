package Foorum::TestUtils;

use strict;
use warnings;
use YAML::XS qw/LoadFile/;    # config
use Foorum::Schema;           # schema
use Cache::FileCache;         # cache
use File::Copy ();
use base 'Exporter';
use vars qw/@EXPORT_OK $config $cache $base_path/;
@EXPORT_OK = qw/
    config
    schema
    cache
    base_path
    rollback_db
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);

sub base_path {
    return $base_path if ($base_path);
    $base_path = abs_path( File::Spec->catdir( $path, '..', '..', '..' ) );
    return $base_path;
}

sub config {
    return $config if ($config);

    $config = LoadFile( File::Spec->catfile( $path, '..', '..', '..', 'foorum.yml' ) );
    if ( -e File::Spec->catfile( $path, '..', '..', '..', 'foorum_local.yml' ) ) {
        my $extra_config = LoadFile(
            File::Spec->catfile( $path, '..', '..', '..', 'foorum_local.yml' ) );
        $config = { %$config, %$extra_config };
    }
    return $config;
}

sub schema {

    # override live cache
    no warnings "all";
    *Foorum::Schema::cache = sub {
        Cache::FileCache->new(
            {   namespace          => 'FoorumTest',
                default_expires_in => 300,
            }
        );
    };

    # create the database
    my $db_file = File::Spec->catfile( $path, 'test.db' );
    my $schema
        = Foorum::Schema->connect( "dbi:SQLite:$db_file", '', '',
        { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
        );

    #unlink $db_file if -e $db_file;
    #$schema->deploy;
    #my $dbh = $schema->storage->dbh;
    #$dbh->do( $_ ) for split /;/, $sql;

    return $schema;
}

sub cache {
    return $cache if ($cache);

    $cache = Cache::FileCache->new(
        {   namespace          => 'FoorumTest',
            default_expires_in => 300,
        }
    );

    return $cache;
}

sub rollback_db {

    # Keep Database the same from original
    File::Copy::copy(
        File::Spec->catfile( $path, 'backup.db' ),
        File::Spec->catfile( $path, 'test.db' )
    );
}

1;
