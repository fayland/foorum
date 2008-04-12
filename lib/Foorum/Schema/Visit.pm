package Foorum::Schema::Visit;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("visit");
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
__PACKAGE__->set_primary_key("user_id", "object_type", "object_id");

sub make_visited : ResultSet {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    return unless ($user_id);
    return
        if (
        $self->count(
            {   user_id     => $user_id,
                object_type => $object_type,
                object_id   => $object_id
            }
        )
        );
    $self->create(
        {   user_id     => $user_id,
            object_type => $object_type,
            object_id   => $object_id,
            time        => time(),
        }
    );
}

sub make_un_visited : ResultSet {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    my @extra_cols;
    if ($user_id) {
        @extra_cols = ( user_id => { '!=', $user_id } );
    }

    $self->search(
        {   object_type => $object_type,
            object_id   => $object_id,
            @extra_cols,
        }
    )->delete;
}

sub is_visited : ResultSet {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    return {} unless ($user_id);
    my $visit;
    my @visits = $self->search(
        {   user_id     => $user_id,
            object_type => $object_type,
            object_id   => $object_id,
        },
        { columns => ['object_id'], }
    )->all;
    foreach (@visits) {
        $visit->{$object_type}->{ $_->object_id } = 1;
    }

    return $visit;
}

1;
