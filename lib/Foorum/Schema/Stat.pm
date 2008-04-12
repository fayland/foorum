package Foorum::Schema::Stat;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stat");
__PACKAGE__->add_columns(
  "stat_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "stat_key",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "stat_value",
  { data_type => "BIGINT", default_value => 0, is_nullable => 0, size => 21 },
  "date",
  { data_type => "DATE", default_value => undef, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("stat_id");

1;
