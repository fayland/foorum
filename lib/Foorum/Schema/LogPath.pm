package Foorum::Schema::LogPath;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("log_path");
__PACKAGE__->add_columns(
  "path_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "session_id",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 72,
  },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "path",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "get",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "post",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "time",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "loadtime",
  { data_type => "DOUBLE", default_value => 0, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("path_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-16 16:59:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BzzSmojAGIKCa60KKSXG/w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
