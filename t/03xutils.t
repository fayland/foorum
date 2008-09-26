#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Foorum::XUtils qw/base_path cache config/;
use File::Spec;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;
my $real = abs_path( File::Spec->catdir( $RealBin, '..' ) );
is( $base_path, $real, 'base_path OK' );

#diag($base_path);

## test config
my $config = config();
ok( $config->{'View::TT'}, 'View::TT config defined' );
is( ref $config->{session}, 'HASH', 'session config is a HASHREF' );

## test cache
SKIP: {
    my $cache_config = $config->{cache}->{backends}->{default};
    my $backend      = $cache_config->{class};
    my $skip_me      = 1;
    if ( $backend eq 'Cache::FileCache' ) {
        $skip_me = 0;
    } elsif ( $backend eq 'Cache::Memcached' ) {
        my $has_io_socket = eval "use IO::Socket::INET; 1;";    ## no critic
        ## no critic (ProhibitStringyEval)
        if ($has_io_socket) {
            my @servers = @{ $cache_config->{servers} };
            my $msock   = IO::Socket::INET->new(
                PeerAddr => $servers[0],
                Timeout  => 3
            );
            if ($msock) {
                $skip_me = 0;
            }
        }
    }

    skip 'cache tests is skipped because it is not usable.', 2 if ($skip_me);

    my $cache = cache();

    my $key = 'Foorum:testfunction:cache';
    my $val = scalar( localtime() );

    $cache->set( $key, $val, 60 );
    my $ret = $cache->get($key);
    is( $ret, $val, 'cache: get ok' );

    $cache->remove($key);
    $ret = $cache->get($key);
    is( $ret, undef, 'cache: get after remove ok' );
}

