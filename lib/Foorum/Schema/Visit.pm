package Foorum::Schema::Visit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("visit");
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
__PACKAGE__->set_primary_key("user_id", "object_type", "object_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-03 14:28:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1c6z0LLS4yMw8RkMENMSzA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
