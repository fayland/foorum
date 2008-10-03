package Foorum::Logger;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base qw/Exporter/;
use vars qw/@EXPORT_OK %levels/;
@EXPORT_OK = qw/ %levels error_log /;

%levels = (
    'info'  => 1,
    'debug' => 2,
    'warn'  => 3,
    'error' => 4,
    'fatal' => 5
);

sub error_log {
    my ( $schema, $level, $text ) = @_;

    return unless ($text);
    
    $leval = exists $levels{$level} ? $levels{$level} : 2; # debug
    
    $schema->resultset('LogError')->create(
        {   level => $level,
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
