package Foorum::Schema::Variables;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("variables");
__PACKAGE__->add_columns(
  "type",
  { data_type => "ENUM", default_value => "global", is_nullable => 0, size => 6 },
  "name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "value",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("type", "name");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-26 14:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UUlOO7515woGNN2vRw9drQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
