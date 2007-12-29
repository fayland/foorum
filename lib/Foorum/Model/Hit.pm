package Foorum::Model::Hit;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub register {
    my ( $self, $c, $object_type, $object_id, $object_hit ) = @_;

    # we update table 'hit' then use Foorum::TheSchwartz::Worker::Hit to update
    # the real table every 5 minutes
    # the status field is time(), after update in real, that will be 0

    my $hit = $c->model('DBIC')->resultset('Hit')->search(
        {   object_type => $object_type,
            object_id   => $object_id,
        }
    )->first;
    my $return_hit;
    if ($hit) {
        $return_hit = $hit->hit_all + 1;
        $hit->update(
            {   hit_new          => \'hit_new + 1',
                hit_all          => \'hit_all + 1',
                last_update_time => time(),
            }
        );
    } else {
        $return_hit = $object_hit || 1;
        $return_hit++;
        $c->model('DBIC')->resultset('Hit')->create(
            {   object_type      => $object_type,
                object_id        => $object_id,
                hit_new          => 1,
                hit_all          => $return_hit,
                hit_today        => 0,
                hit_yesterday    => 0,
                hit_weekly       => 0,
                hit_monthly      => 0,
                last_update_time => time(),
            }
        );
    }

    return $return_hit;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut

1;
