package Foorum::Controller::Admin::Tools;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;

sub flush_cache : Local {
    my ( $self, $c ) = @_;

    my $result = $c->cache->flush_all;

    $c->stash(
        {   template => 'admin/index.html',
            message  => Dumper( \$result ),
        }
    );
}

sub cache_stat : Local {
    my ( $self, $c ) = @_;

    my $result = $c->cache->stats;

    $c->stash(
        {   template => 'admin/index.html',
            message  => Dumper( \$result ),
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
