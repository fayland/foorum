package Foorum::Model::BannedIP;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub get {
    my ( $self, $c ) = @_;

    my $cache_key  = 'global|banned_ip';
    my $cache_data = $c->cache->get($cache_key);
    return wantarray ? @{$cache_data} : $cache_data
        if ( $cache_data and ref($cache_data) eq 'ARRAY' );
    $cache_data = [];

    my $rs = $c->model('DBIC')->resultset('BannedIp')->search();
    while ( my $rec = $rs->next ) {
        push @{$cache_data}, $rec->cidr_ip;
    }
    $c->cache->set( $cache_key, $cache_data );
    return wantarray ? @{$cache_data} : $cache_data;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
