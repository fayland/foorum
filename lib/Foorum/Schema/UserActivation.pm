package Foorum::Schema::UserActivation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("user_activation");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "activation_code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "new_email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("user_id");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-26 14:37:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fz51F23RPEVLG4SaTO71FQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
