package Foorum::Logger;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base qw/Exporter/;
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/ error_log /;

sub error_log {
    my ( $schema, $level, $text ) = @_;

    return unless ($text);
    $schema->resultset('LogError')->create(
        {   level => $level || 'debug',
            text  => $text,
            time  => time(),
        }
    );
}

1;
__END__

=pod

=head1 NAME

Foorum::Logger - Foorum Logger

=head1 FUNCTIONS

=over 4

=item error_log

insert log into table 'log_error'

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
