package Foorum::Schema::EmailSetting;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("email_setting");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "object_type",
  {
    data_type => "ENUM",
    default_value => "comment",
    is_nullable => 0,
    size => 7,
  },
  "frequence",
  { data_type => "ENUM", default_value => "daily", is_nullable => 0, size => 6 },
);
__PACKAGE__->set_primary_key("user_id", "object_type");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DW/6l2kIAVxZYgog4nGNUw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
