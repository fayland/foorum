package Foorum::Schema::Poll;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("poll");
__PACKAGE__->add_columns(
  "poll_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "author_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "multi",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "anonymous",
  { data_type => "ENUM", default_value => 0, is_nullable => 0, size => 1 },
  "time",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "duration",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "vote_no",
  { data_type => "MEDIUMINT", default_value => 0, is_nullable => 0, size => 8 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "hit",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("poll_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5qCjFiC01PoxQ7hJ9DG75A


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->might_have(
    'author' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.author_id' }
);
__PACKAGE__->has_many(
    'options' => 'Foorum::Schema::PollOption',
    { 'foreign.poll_id' => 'self.poll_id' }
);
__PACKAGE__->has_many(
    'results' => 'Foorum::Schema::PollResult',
    { 'foreign.poll_id' => 'self.poll_id' }
);
1;
