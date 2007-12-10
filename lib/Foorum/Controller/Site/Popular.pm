package Foorum::Controller::Site::Popular;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Data::Dumper;

sub default : Private {
    my ($self, $c, undef, undef, $type) = @_;
    
    unless ($type and grep { $type eq $_ } ('weekly', 'monthly', 'yesterday','all')) {
        $type = 'today'; # default
    }
    
    my $page = get_page_from_url( $c->req->path );
    my $hit_rs = $c->model('DBIC')->resultset('Hit')->search( undef, {
        rows => 20, page => $page,
        order_by => "hit_${type} DESC",
    } );
    
    my @objects;
    while (my $rec = $hit_rs->next) {
        my $object = $c->model('Object')->get_object_by_type_id(
            $c,
            {   object_type => $rec->object_type,
                object_id   => $rec->object_id,
            }
        );
        next unless ($object);
        push @objects,
            {
            object_type => $rec->object_type,
            object_id   => $rec->object_id,
            object      => $object,
            hit_rs      => $rec,
            };
    }
    
    my $url_prefix = $c->req->path;
    $url_prefix =~ s/\/page=\d+((\/)|$)/$2/isg;
    
    $c->stash( {
        template => 'site/popular.html',
        type     => $type,
        url_prefix => $url_prefix,
        pager    => $hit_rs->pager,
        objects  => \@objects,
    } );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
