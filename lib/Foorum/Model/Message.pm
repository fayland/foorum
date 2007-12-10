package Foorum::Model::Message;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub remove_from_db {
    my ( $self, $c, $message_id ) = @_;

    $c->model('DBIC::Message')->search( { message_id => $message_id } )
        ->delete;
    $c->model('DBIC::MessageUnread')->search( { message_id => $message_id } )
        ->delete;
}

sub are_messages_unread {
    my ( $self, $c, $message_ids ) = @_;

    return unless ( $c->user_exists );
    my @rs = $c->model('DBIC::MessageUnread')->search(
        {   user_id    => $c->user->user_id,
            message_id => $message_ids,
        },
        { columns => ['message_id'], }
    )->all;

    my $unread;
    $unread->{ $_->message_id } = 1 foreach (@rs);

    return $unread;
}

1;

__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut
