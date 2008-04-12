package Foorum::Schema::ForumSettings;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("forum_settings");
__PACKAGE__->add_columns(
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
  "value",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 48,
  },
);
__PACKAGE__->set_primary_key("forum_id", "type");

1;
