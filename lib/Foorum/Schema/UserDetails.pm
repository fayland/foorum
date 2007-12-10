package Foorum::Schema::UserDetails;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_details");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "qq",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "msn",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "yahoo",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "skype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "gtalk",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "homepage",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "birthday",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("user_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jaukhnvB5wYZWZUvzyN32A


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
    'user' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.user_id' }
);
1;
