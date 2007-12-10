package Foorum::ExternalUtils;

use strict;
use warnings;
use YAML qw/LoadFile/; # config
use Foorum::Schema; # schema
use Cache::Memcached; # memcached
use TheSchwartz; # theschwartz
use Template; # template
use Template::Stash::XS;
use base 'Exporter';
use vars qw/@EXPORT_OK $config $schema $memcached $theschwartz $tt2/;
@EXPORT_OK = qw/
    config
    schema
    memcached
    theschwartz
    tt2
/;

use File::Spec;
my (undef, $path) = File::Spec->splitpath(__FILE__);

sub config {
    
    return $config if ($config);
    
    $config = LoadFile("$path/../../foorum.yml");
    my $extra_config = LoadFile("$path/../../foorum_local.yml");
    $config = { %$config, %$extra_config };
    return $config;
}

sub schema {
    
    return $schema if ($schema);
    $config = config() unless ($config);
    
    $schema = Foorum::Schema->connect(
        $config->{dsn},
        $config->{dsn_user},
        $config->{dsn_pwd},
        { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
    );
    return $schema;
}

sub memcached {
    
    return $memcached if ($memcached);
    $config = config() unless ($config);
    
    my $params = { %{ $config->{cache} } };
    $memcached = Cache::Memcached->new($params);
    return $memcached;
}

sub theschwartz {
    
    return $theschwartz if ($theschwartz);
    $config = config() unless ($config);
    
    $theschwartz = TheSchwartz->new(
        databases => [ {
            dsn  => $config->{theschwartz_dsn},
            user => $config->{dsn_user},
            pass => $config->{dsn_pwd},
        } ],
        verbose => 1,
    );
    return $theschwartz;
}

sub tt2 {
    
    return $tt2 if ($tt2);
    $config = config() unless ($config);
    
    $tt2 = Template->new( {
	    INCLUDE_PATH => [ "$path/../../templates" ],
		PRE_CHOMP  => 1,
        POST_CHOMP => 1,
        STASH      => Template::Stash::XS->new,
	} );
    return $tt2;
}

1;
