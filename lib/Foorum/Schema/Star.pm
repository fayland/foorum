package Foorum::Schema::Star;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("star");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "object_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 12 },
  "object_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("user_id", "object_id", "object_type");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zFf5MOZPkHKH+9fVp0n9IQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
