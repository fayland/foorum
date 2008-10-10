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

__PACKAGE__->resultset_class('Foorum::ResultSet::SecurityCode');

1;
__END__

=pod

=head1 NAME

Foorum::Schema::SecurityCode - Table 'security_code'

=head1 COLUMNS

=over 4

=item security_code_id

INT(11)

NOT NULL, PRIMARY KEY

=item user_id

INT(11)

NOT NULL

=item type

TINYINT(1)

NOT NULL

=item code

VARCHAR(12)

NOT NULL

=item time

INT(11)

NOT NULL

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

