package Foorum::Schema::LogPath;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
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
    data_type => "INT",
    default_value => 0,
    is_nullable => 0,
    size => 11,
  },
  "loadtime",
  { data_type => "DOUBLE", default_value => 0, is_nullable => 0, size => 64 },
);
__PACKAGE__->set_primary_key("path_id");

1;
