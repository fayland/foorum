package Foorum::Schema::Share;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("share");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "object_type",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 12 },
  "object_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "time",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
);
__PACKAGE__->set_primary_key("user_id", "object_id", "object_type");

sub del_or_create : ResultSet {
    my ( $self, $cond ) = @_;

    my $count = $self->count($cond);
    if ($count) {
        $self->search($cond)->delete;
        return 0;
    } else {
        $cond->{time} = time();
        $self->create($cond);
        return 1;
    }
}

1;
