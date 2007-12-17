package Foorum::Schema::LogAction;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("log_action");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "action",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 24,
  },
  "object_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "object_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "time",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "text",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-17 14:14:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JsTedkIfJWmcjE58rUcA/w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
