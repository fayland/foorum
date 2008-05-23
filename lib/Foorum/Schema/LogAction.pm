package Foorum::Schema::LogAction;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
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
    data_type => 'INT',
    default_value => 0,
    is_nullable => 0,
    size => 11,
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

1;
