package Foorum::Schema::LogError;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("log_error");
__PACKAGE__->add_columns(
  "error_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "level",
  { data_type => "ENUM", default_value => "debug", is_nullable => 0, size => 5 },
  "text",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
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
__PACKAGE__->set_primary_key("error_id");

1;
__END__

=pod

=head1 NAME

Foorum::Schema::LogError - Table 'log_error'

=head1 COLUMNS

=over 4

=item error_id

INT(11)

NOT NULL, PRIMARY KEY

=item level

ENUM(5)

NOT NULL, DEFAULT VALUE 'debug'

=item text

TEXT(65535)

NOT NULL

=item time

INT(11)

NOT NULL

=back

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

