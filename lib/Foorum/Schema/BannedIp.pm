package Foorum::Schema::BannedIp;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
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

__PACKAGE__->resultset_class('Foorum::ResultSet::BannedIp');

1;
