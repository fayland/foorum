package Foorum::Schema::Message;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("message");
__PACKAGE__->add_columns(
  "message_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "from_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "to_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "text",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "post_on",
  {
    data_type => "INT",
    default_value => 0,
    is_nullable => 0,
    size => 11,
  },
  "post_ip",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "from_status",
  { data_type => "ENUM", default_value => "open", is_nullable => 0, size => 7 },
  "to_status",
  { data_type => "ENUM", default_value => "open", is_nullable => 0, size => 7 },
);
__PACKAGE__->set_primary_key("message_id");


__PACKAGE__->has_one(
    'sender' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.from_id' }
);
__PACKAGE__->has_one(
    'recipient' => 'Foorum::Schema::User',
    { 'foreign.user_id' => 'self.to_id' }
);

sub remove_from_db : ResultSet {
    my ( $self, $message_id ) = @_;

    my $schema = $self->result_source->schema;

    $self->search( { message_id => $message_id } )->delete;
    $schema->resultset('MessageUnread')->search( { message_id => $message_id } )->delete;
}

sub are_messages_unread : ResultSet {
    my ( $self, $user_id, $message_ids ) = @_;

    return unless ($user_id);

    my $schema = $self->result_source->schema;
    my @rs     = $schema->resultset('MessageUnread')->search(
        {   user_id    => $user_id,
            message_id => $message_ids,
        },
        { columns => ['message_id'], }
    )->all;

    my $unread;
    $unread->{ $_->message_id } = 1 foreach (@rs);

    return $unread;
}

sub get_unread_cnt : ResultSet {
    my ( $self, $user_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cachekey = "global|message_unread_cnt|user_id=$user_id";
    my $cacheval = $cache->get($cachekey);

    if ($cacheval) {
        return $cacheval->{val};
    } else {
        my $cnt = $schema->resultset('MessageUnread')->count( { user_id => $user_id } );
        $cache->set( $cachekey, { val => $cnt, 1 => 2 }, 1800 );    # half an hour

        return $cnt;
    }
}

1;
