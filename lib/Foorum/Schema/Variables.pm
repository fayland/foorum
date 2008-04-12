package Foorum::Schema::Variables;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("variables");
__PACKAGE__->add_columns(
  "type",
  { data_type => "ENUM", default_value => "global", is_nullable => 0, size => 6 },
  "name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "value",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("type", "name");

1;
