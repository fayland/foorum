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
__END__

=pod

=head1 NAME

Foorum::Schema::ForumSettings - Table 'forum_settings'

=head1 COLUMNS

=over 4

=item forum_id

INT(11)

NOT NULL, PRIMARY KEY

=item type

VARCHAR(48)

NOT NULL, PRIMARY KEY

=item value

VARCHAR(48)

NOT NULL

=back

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

