package Foorum::TestUtils;

use strict;
use warnings;
use YAML::XS qw/LoadFile/;    # config
use Foorum::Schema;           # schema
use Cache::FileCache;         # cache
use base 'Exporter';
use vars qw/@EXPORT_OK $config $cache $base_path/;
@EXPORT_OK = qw/
    config
    schema
    cache
    base_path
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub base_path {
    return $base_path if ($base_path);
    $base_path = abs_path("$path/../../../");
    return $base_path;
}

sub config {
    return $config if ($config);

    $config = LoadFile("$path/../../../foorum.yml");
    if ( -e "$path/../../../foorum_local.yml" ) {
        my $extra_config = LoadFile("$path/../../../foorum_local.yml");
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
    my $db_file = "$path/test.db";
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

1;
