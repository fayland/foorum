package Foorum::Schema::UserRole;

use strict;
use warnings;

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


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ndOMLFXd2xkUZN4yMm5Sw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
    'user' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.user_id' }
);
1;
