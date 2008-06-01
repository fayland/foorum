package Foorum::Schema::ScheduledEmail;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table("scheduled_email");
__PACKAGE__->add_columns(
  "email_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "email_type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 24,
  },
  "processed",
  { data_type => "ENUM", default_value => "N", is_nullable => 0, size => 1 },
  "from_email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "to_email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
  "subject",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "plain_body",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "html_body",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "time",
  {
    data_type => 'INT',
    default_value => 0,
    is_nullable => 0,
    size => 11,
  },
);
__PACKAGE__->set_primary_key("email_id");

__PACKAGE__->resultset_class('Foorum::ResultSet::ScheduledEmail');

1;
