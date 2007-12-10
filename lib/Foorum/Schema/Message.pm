package Foorum::Schema::Message;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("message");
__PACKAGE__->add_columns(
  "message_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "from_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "to_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "title",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "text",
  { data_type => "TEXT", default_value => "", is_nullable => 0, size => 65535 },
  "post_on",
  { data_type => "DATETIME", default_value => "", is_nullable => 0, size => 19 },
  "post_ip",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "from_status",
  { data_type => "ENUM", default_value => "open", is_nullable => 0, size => 7 },
  "to_status",
  { data_type => "ENUM", default_value => "open", is_nullable => 0, size => 7 },
);
__PACKAGE__->set_primary_key("message_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FVjX1LDj50ZvxpwoAlF7ig


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_one(
    'sender' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.from_id' }
);
__PACKAGE__->has_one(
    'recipient' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.to_id' }
);
1;
