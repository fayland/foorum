package Foorum::ResultSet::UserForum;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub create_user_forum {
    my ( $self, $info ) = @_;

    $self->create(
        {   user_id  => $info->{user_id},
            forum_id => $info->{forum_id},
            status   => $info->{status},
        }
    );

    $self->clear_cached_policy($info);
}

sub remove_user_forum {
    my ( $self, $info ) = @_;

    my @wheres;
    push @wheres, ( user_id => $info->{user_id} ) if ( $info->{user_id} );
    push @wheres, ( forum_id => $info->{forum_id} )   if ( $info->{forum_id} );
    push @wheres, ( status  => $info->{status} )    if ( $info->{status} );

    return unless ( scalar @wheres );

    $self->search( { @wheres, } )->delete;

    $self->clear_cached_policy($info);
}

sub clear_cached_policy {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    if ( $info->{user_id} ) {
        # clear user cache too
        $schema->resultset('User')
            ->delete_cache_by_user_cond( { user_id => $info->{user_id} } );
    }

    if ( $info->{forum_id} ) {
        $cache->remove("policy|user_role|forum_id=$info->{forum_id}");
    }

}

1;
__END__
