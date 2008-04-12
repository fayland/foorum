package Foorum::Schema::BannedIp;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("banned_ip");
__PACKAGE__->add_columns(
  "ip_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "cidr_ip",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 20 },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("ip_id");

use Net::IP::Match::Regexp qw( create_iprange_regexp match_ip );

sub get : ResultSet {
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

sub is_ip_banned : ResultSet {
    my ( $self, $ip ) = @_;

    my @cidr_ips = $self->get();
    if ( scalar @cidr_ips ) {
        my $regexp = create_iprange_regexp(@cidr_ips);
        if ( match_ip( $ip, $regexp ) ) {
            return 1;
        }
    }

    return 0;
}

1;
