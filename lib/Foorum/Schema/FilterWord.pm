package Foorum::Schema::FilterWord;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("filter_word");
__PACKAGE__->add_columns(
  "word",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "type",
  {
    data_type => "ENUM",
    default_value => "username_reserved",
    is_nullable => 0,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("word", "type");


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-22 16:10:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AQjOqeDoRGYrCr6NbysRjQ


















# You can replace this text with custom content, and it will be preserved on regeneration
1;
