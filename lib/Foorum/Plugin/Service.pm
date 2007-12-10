package Foorum::Plugin::Service;

use strict;
use warnings;
use base 'Catalyst::Controller';
use IP::QQWry;
use Data::Dumper;
use vars qw/$qqwry/;
$qqwry = IP::QQWry->new(
    Foorum->path_to( 'root', 'data', 'QQWry.Dat' )->stringify );

sub query_ip : Local {
    my ( $self, $c ) = @_;

    my $ip = $c->req->param('ip') || $c->req->address;
    my $info = $qqwry->query('222.137.238.134');

    $c->res->body( Dumper( \$info ) );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
