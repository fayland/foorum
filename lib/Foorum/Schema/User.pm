package Foorum::Schema::User;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => "000000",
    is_nullable => 0,
    size => 32,
  },
  "nickname",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 100,
  },
  "gender",
  { data_type => "ENUM", default_value => "NA", is_nullable => 0, size => 2 },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "register_time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "register_ip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "last_login_on",
  {
    data_type => "INT",
    default_value => 0,
    is_nullable => 1,
    size => 11,
  },
  "last_login_ip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "login_times",
  { data_type => "MEDIUMINT", default_value => 1, is_nullable => 0, size => 8 },
  "status",
  {
    data_type => "ENUM",
    default_value => "unverified",
    is_nullable => 0,
    size => 10,
  },
  "threads",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "replies",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "lang",
  { data_type => "CHAR", default_value => "cn", is_nullable => 1, size => 2 },
  "country",
  { data_type => "CHAR", default_value => "cn", is_nullable => 1, size => 2 },
  "state_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "city_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->add_unique_constraint("email", ["email"]);
__PACKAGE__->add_unique_constraint("username", ["username"]);

__PACKAGE__->might_have(
    'details' => 'Foorum::Schema::UserDetails',
    { 'foreign.user_id' => 'self.user_id' }
);

__PACKAGE__->resultset_class('Foorum::ResultSet::User');

1;
