package Foorum::TestUtils;

use YAML qw/LoadFile/;    # config
use Foorum::Schema;       # schema
use Template;             # template
use Template::Stash::XS;
use Cache::FileCache;     # cache
use base 'Exporter';
use vars qw/@EXPORT_OK $config $schema $cache $tt2/;
@EXPORT_OK = qw/
    config
    schema
    cache
    tt2
    /;

use File::Spec;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub config {
    return $config if ($config);

    $config = LoadFile("$path/../../../foorum.yml");
    my $extra_config = LoadFile("$path/../../../foorum_local.yml");
    $config = { %$config, %$extra_config };
    return $config;
}

sub schema {
    return $schema if ($schema);
    
    # override live cache
    $Foorum::Schema::cache = cache();
    
    # create the database
    my $db_file = "$path/test.db";
    $schema = Foorum::Schema->connect( "dbi:SQLite:$db_file", '', '',
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

    $cache = Cache::FileCache->new( {
        namespace => 'FoorumTest',
        default_expires_in => 300,
    } );

    return $cache;
}

sub tt2 {
    return $tt2 if ($tt2);
    $config = config() unless ($config);

    $tt2 = Template->new(
        {   INCLUDE_PATH => ["$path/../../../templates"],
            PRE_CHOMP    => 1,
            POST_CHOMP   => 1,
            STASH        => Template::Stash::XS->new,
        }
    );
    return $tt2;
}

1;