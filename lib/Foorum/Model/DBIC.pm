package Foorum::Model::DBIC;

use strict;
use Foorum::Version; our $VERSION = $Foorum::VERSION;

BEGIN {
    my $use_base_module = 'Catalyst::Model::DBIC::Schema';
    if ( Foorum->config->{debug_mode} ) {
        my $querylog = 'Catalyst::Model::DBIC::Schema::QueryLog';
        my $has = eval("use $querylog;1;"); ## no critic (ProhibitStringyEval)
        $use_base_module = $querylog if ($has);
    }
    eval("use base '$use_base_module';");   ## no critic (ProhibitStringyEval)
}

__PACKAGE__->config(
    schema_class => 'Foorum::Schema',
    connect_info => [
        Foorum->config->{dsn},
        Foorum->config->{dsn_user},
        Foorum->config->{dsn_pwd},
        { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
    ],
);

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
