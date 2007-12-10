package Foorum::Controller::StaticInfo;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub help : Global {
    my ( $self, $c, $help_id ) = @_;

    __serve_static_info( $c, 'help', $help_id );
}

sub info : Global {
    my ( $self, $c, $info_id ) = @_;

    __serve_static_info( $c, 'info', $info_id );
}

sub __serve_static_info {
    my ( $c, $type, $type_id ) = @_;

    $c->stash->{template}                  = "$type/index.html";
    $c->stash->{additional_template_paths} = [
        $c->path_to( 'templates', $c->stash->{lang} ),
        $c->path_to( 'templates', 'en' )
    ];

    if ( $c->req->param('ajax') ) {
        $c->stash->{simple_wrapper} = 1;
    }

    # help/info templates in under its own templates/$lang/help
    # since too many text needs translation.
    if ($type_id) {
        $type_id =~ s/\W+//isg;
        if (-e $c->path_to( 'templates', $c->stash->{lang}, $type,
                "$type_id.html" )
            or ( $c->stash->{lang} ne 'en'
                and
                -e $c->path_to( 'templates', 'en', $type, "$type_id.html" ) )
            )
        {
            $c->stash->{template} = "$type/$type_id.html";
        }
    }
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
