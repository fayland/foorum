package Foorum::Schema::LogError;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("log_error");
__PACKAGE__->add_columns(
  "error_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "level",
  { data_type => "ENUM", default_value => "debug", is_nullable => 0, size => 5 },
  "text",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "time",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("error_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-17 14:14:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e9OPwU9PLXmNgCmGZTAUoQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
