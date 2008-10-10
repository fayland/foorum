package Foorum::Schema::SecurityCode;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("security_code");
__PACKAGE__->add_columns(
  "security_code_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "type",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
  "code",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 12,
  },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("security_code_id");


1;
__END__
