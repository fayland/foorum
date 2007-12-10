package Foorum::Schema::UserProfilePhoto;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_profile_photo");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  { data_type => "ENUM", default_value => "upload", is_nullable => 0, size => 6 },
  "value",
  { data_type => "VARCHAR", default_value => 0, is_nullable => 0, size => 255 },
  "width",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "height",
  { data_type => "SMALLINT", default_value => 0, is_nullable => 0, size => 6 },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YqsUuqncr8Pu1CFjXAz85w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
