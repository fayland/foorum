package Foorum::Schema::UserSettings;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_settings");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
  "value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
);
__PACKAGE__->set_primary_key("user_id", "type");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-27 21:11:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kCHUmaOU+ZQFvsaDLYI+CA


# You can replace this text with custom content, and it will be preserved on regeneration
1;