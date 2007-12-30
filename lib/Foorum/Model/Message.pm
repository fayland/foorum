package Foorum::Model::Message;

use strict;
use warnings;
use base 'Catalyst::Model';

sub remove_from_db {
    my ( $self, $c, $message_id ) = @_;

    $c->model('DBIC::Message')->search( { message_id => $message_id } )->delete;
    $c->model('DBIC::MessageUnread')->search( { message_id => $message_id } )->delete;
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

sub get_unread_cnt {
    my ( $self, $c, $user_id ) = @_;

    my $cachekey = "global|message_unread_cnt|user_id=$user_id";
    my $cacheval = $c->cache->get($cachekey);

    if ($cacheval) {
        return $cacheval->{val};
    } else {
        my $cnt = $c->model('DBIC::MessageUnread')->count( { user_id => $user_id } );
        $c->cache->set( $cachekey, { val => $cnt, 1 => 2 }, 1800 );    # half an hour

        return $cnt;
    }
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
