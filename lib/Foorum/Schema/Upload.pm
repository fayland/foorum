package Foorum::Schema::Upload;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("upload");
__PACKAGE__->add_columns(
  "upload_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 36,
  },
  "filesize",
  { data_type => "DOUBLE", default_value => undef, is_nullable => 1, size => 64 },
  "filetype",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("upload_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fnvQTVwdfAp4pIVMbSm9cA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
