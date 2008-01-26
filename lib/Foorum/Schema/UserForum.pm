package Foorum::Schema::UserForum;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_forum");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "status",
  { data_type => "ENUM", default_value => "user", is_nullable => 0, size => 9 },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user_id", "forum_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-26 14:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SOIHm6FrGtu8OcQ9O9IfZA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->resultset_class('Foorum::ResultSet::UserForum');

1;
