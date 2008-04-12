package Foorum::Schema::UserRole;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "role",
  { data_type => "ENUM", default_value => "user", is_nullable => 1, size => 9 },
  "field",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
);

__PACKAGE__->belongs_to(
    'user' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.user_id' }
);
1;
