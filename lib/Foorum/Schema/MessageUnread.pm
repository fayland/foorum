package Foorum::Schema::MessageUnread;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("message_unread");
__PACKAGE__->add_columns(
  "message_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("message_id", "user_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-17 14:14:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PZNfVIpxPlNPCgvW2xLyvA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
