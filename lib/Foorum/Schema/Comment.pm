package Foorum::Schema::Comment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("comment");
__PACKAGE__->add_columns(
  "comment_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "reply_to",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "text",
  { data_type => "TEXT", default_value => "", is_nullable => 0, size => 65535 },
  "post_on",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "update_on",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "post_ip",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "formatter",
  {
    data_type => "VARCHAR",
    default_value => "ubb",
    is_nullable => 0,
    size => 16,
  },
  "object_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 30 },
  "object_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "author_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "title",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "upload_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("comment_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6D2rOUYwma7PssP9pQz2qg


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->might_have(
    'upload' => 'Foorum::Schema::Upload',
    { 'foreign.upload_id' => 'self.upload_id' }
);
1;
