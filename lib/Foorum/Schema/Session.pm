package Foorum::Schema::Session;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("session");
__PACKAGE__->add_columns(
  "id",
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 72 },
  "session_data",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "expires",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 11 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "path",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-26 14:47:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MRKPIa3uv8S7ajob9MHwDA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
