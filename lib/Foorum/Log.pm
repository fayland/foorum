package Foorum::Log;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/
    error_log
    /;

sub error_log {
    my ( $schema, $level, $text ) = @_;

    return unless ($text);
    $schema->resultset('LogError')->create(
        {   level => $level || 'debug',
            text => $text,
            time => \'NOW()',
        }
    );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
