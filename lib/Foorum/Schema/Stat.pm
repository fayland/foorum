package Foorum::Schema::Stat;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stat");
__PACKAGE__->add_columns(
  "stat_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "stat_key",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "stat_value",
  { data_type => "BIGINT", default_value => 0, is_nullable => 0, size => 21 },
  "date",
  { data_type => "DATE", default_value => "", is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("stat_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g2llIx1UVy7tS3WBEuMbAQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
