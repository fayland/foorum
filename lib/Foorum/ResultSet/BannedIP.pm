package Foorum::ResultSet::BannedIP;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub get {
    my ($self) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key  = 'global|banned_ip';
    my $cache_data = $cache->get($cache_key);
    return wantarray ? @{$cache_data} : $cache_data
        if ( $cache_data and ref($cache_data) eq 'ARRAY' );
    $cache_data = [];

    my $rs = $schema->resultset('BannedIp')->search();
    while ( my $rec = $rs->next ) {
        push @{$cache_data}, $rec->cidr_ip;
    }
    $cache->set( $cache_key, $cache_data );
    return wantarray ? @{$cache_data} : $cache_data;
}

1;
__END__
