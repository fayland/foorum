package Foorum::Schema::Topic;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table("topic");
__PACKAGE__->add_columns(
  "topic_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "closed",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "sticky",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "elite",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "hit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "last_updator_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "last_update_date",
  {
    data_type => "INT",
    default_value => 0,
    is_nullable => 1,
    size => 11,
  },
  "author_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "total_replies",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "status",
  {
    data_type => "ENUM",
    default_value => "healthy",
    is_nullable => 0,
    size => 7,
  },
);
__PACKAGE__->set_primary_key("topic_id");

__PACKAGE__->might_have(
    'author' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.author_id' }
);
__PACKAGE__->might_have(
    'last_updator' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.last_updator_id' }
);
__PACKAGE__->belongs_to(
    'forum' => 'Foorum::Schema::Forum',
    { 'foreign.forum_id' => 'self.forum_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::Topic');

1;
