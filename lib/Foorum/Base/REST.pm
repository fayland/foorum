package Foorum::Base::REST;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller::REST';

__PACKAGE__->config(
    serialize => {
         'stash_key' => 'rest',
         'map'       => {
            'text/html'        => [ 'View', 'TT' ],
            'application/json' => 'JSON',
            'text/x-json'      => 'JSON',
          },
    }
);


1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
