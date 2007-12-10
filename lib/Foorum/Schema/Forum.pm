package Foorum::Schema::Forum;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("forum");
__PACKAGE__->add_columns(
  "forum_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "forum_code",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 25 },
  "name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 100 },
  "description",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "forum_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 16 },
  "policy",
  { data_type => "ENUM", default_value => "public", is_nullable => 0, size => 9 },
  "total_members",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 8 },
  "total_topics",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "total_replies",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "last_post_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "status",
  {
    data_type => "ENUM",
    default_value => "healthy",
    is_nullable => 0,
    size => 7,
  },
);
__PACKAGE__->set_primary_key("forum_id");
__PACKAGE__->add_unique_constraint("forum_code", ["forum_code"]);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RgqW9otWUUDMUPt21oFCrA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->has_many(
    'topics' => 'Foorum::Schema::Topic',
    { 'foreign.forum_id' => 'self.forum_id' }
);
1;
