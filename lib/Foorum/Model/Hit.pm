package Foorum::Model::Hit;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub register {
    my ($self, $c, $object_type, $object_id, $object_hit) = @_;
    
    my $hit = $c->model('DBIC')->resultset('Hit')->search( {
        object_type => $object_type,
        object_id   => $object_id,
    } )->first;
    my $return_hit;
    if ($hit) {
        $return_hit = $hit->hit_all + 1;
        $hit->update( {
            hit_new => \'hit_new + 1',
            hit_all => \'hit_all + 1',
            last_update_time => time(),
        } );
    } else {
        $return_hit = $object_hit || 1;
        $return_hit++;
        $c->model('DBIC')->resultset('Hit')->create( {
            object_type => $object_type,
            object_id   => $object_id,
            hit_new     => 1,
            hit_all     => $return_hit,
            hit_today   => 0,
            hit_yesterday => 0,
            hit_weekly    => 0,
            hit_monthly   => 0,
            last_update_time => time(),
        } );
    }
    
    # update filed randomly.
    if (int(rand(1000)) % 30 == 1) {
        update_hit_object($self, $c, $object_type, $object_id, $return_hit);
    }
    
    return $return_hit;
}

sub update_hit_object {
    my ($self, $c, $object_type, $object_id, $hit) = @_;
    
    if ($object_type eq 'topic') {
        $c->model('Topic')->update( $c, $object_id, {
            hit => $hit,
        } );
    } elsif ($object_type eq 'poll') {
        $c->model('DBIC')->resultset('Poll')->search( {
            poll_id => $object_id,
        } )->update( {
            hit => $hit,
        } );
    }
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
