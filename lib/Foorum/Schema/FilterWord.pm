package Foorum::Schema::FilterWord;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);
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

__PACKAGE__->resultset_class('Foorum::ResultSet::FilterWord');

1;
