package Foorum::ExternalUtils;

use strict;
use warnings;
use YAML qw/LoadFile/;    # config
use Foorum::Schema;       # schema
use TheSchwartz;          # theschwartz
use Template;             # template
use Template::Stash::XS;
use base 'Exporter';
use vars qw/@EXPORT_OK $base_path $config $schema $cache $theschwartz $tt2/;
@EXPORT_OK = qw/
    base_path
    config
    schema
    cache
    theschwartz
    tt2
    error_log
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub base_path {
    return $base_path if ($base_path);
    $base_path = abs_path("$path/../../");
    return $base_path;
}

sub config {

    return $config if ($config);

    $config = LoadFile("$path/../../foorum.yml");
    my $extra_config = LoadFile("$path/../../foorum_local.yml");
    $config = { %$config, %$extra_config };
    return $config;
}

sub schema {

    return $schema if ($schema);
    $config = config() unless ($config);

    $schema
        = Foorum::Schema->connect( $config->{dsn}, $config->{dsn_user},
        $config->{dsn_pwd}, { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
        );
    return $schema;
}

sub cache {

    return $cache if ($cache);
    $config = config() unless ($config);

    my %params = %{ $config->{cache}{backends}{default} };
    my $class  = delete $params{class};

    eval("use $class;");    ## no critic (ProhibitStringyEval)
    unless ($@) {
        $cache = $class->new( \%params );
    }

    return $cache;
}

sub theschwartz {

    return $theschwartz if ($theschwartz);
    $config = config() unless ($config);

    $theschwartz = TheSchwartz->new(
        databases => [
            {   dsn  => $config->{theschwartz_dsn},
                user => $config->{theschwartz_user} || $config->{dsn_user},
                pass => $config->{theschwartz_pwd} || $config->{dsn_pwd},
            }
        ],
        verbose => 0,
    );

    return $theschwartz;
}

sub tt2 {

    return $tt2 if ($tt2);
    $config = config() unless ($config);

    $tt2 = Template->new(
        {   INCLUDE_PATH => ["$path/../../templates"],
            PRE_CHOMP    => 1,
            POST_CHOMP   => 1,
            STASH        => Template::Stash::XS->new,
        }
    );
    return $tt2;
}

sub error_log {
    my ( $schema, $level, $text ) = @_;

    return unless ($text);
    $schema->resultset('LogError')->create(
        {   level => $level || 'debug',
            text => $text,
            time => \'NOW()',    #'
        }
    );
}

1;
__END__

=pod

=head1 NAME

Foorum::ExternalUtils - Utils for cron

=head1 FUNCTIONS

=over 4

=item base_path

the same as $c->config->{home} or $c->path_to

=item config

the same as $c->config expect ->{home}

=item schema

the same as $c->model('DBIC')

=item cache

the same as $c->cache

=item tt2

generally like $c->view('TT'), yet a bit different

=item theschwartz

TheSchwartz->new with correct database from $config

=item error_log

insert log into table 'log_error'

=back

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
