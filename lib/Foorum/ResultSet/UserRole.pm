package Foorum::ResultSet::UserRole;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub create_user_role {
    my ( $self, $info ) = @_;

    $self->create(
        {   user_id => $info->{user_id},
            field   => $info->{field},
            role    => $info->{role},
        }
    );

    $self->clear_cached_policy($info);
}

sub remove_user_role {
    my ( $self, $info ) = @_;

    my @wheres;
    push @wheres, ( user_id => $info->{user_id} ) if ( $info->{user_id} );
    push @wheres, ( field   => $info->{field} )   if ( $info->{field} );
    push @wheres, ( role    => $info->{role} )    if ( $info->{role} );

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

    # field_id != 'site'
    if ($info->{field} =~ /^\d+$/
        and (  not $info->{role}
            or $info->{role} eq 'admin'
            or $info->{role} eq 'moderator' )
        ) {
        $info->{forum_id} = $info->{field};
    }

    if ( $info->{forum_id} ) {
        $cache->remove("policy|user_role|forum_id=$info->{forum_id}");
    }

}

1;
__END__
