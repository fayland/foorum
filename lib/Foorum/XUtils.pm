package Foorum::XUtils;

use strict;
use warnings;

use Foorum::Version; our $VERSION = $Foorum::VERSION;

use YAML::XS qw/LoadFile/;    # config
use TheSchwartz;              # theschwartz
use Template;                 # template
use Template::Stash::XS;
use base 'Exporter';
use vars qw/@EXPORT_OK $base_path $config $cache $tt2 $theschwartz/;
@EXPORT_OK = qw/
    base_path
    config
    cache
    tt2
    theschwartz
    /;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub base_path {
    return $base_path if ($base_path);
    $base_path = abs_path( File::Spec->catdir( $path, '..', '..' ) );
    return $base_path;
}

sub config {

    return $config if ($config);

    $config = LoadFile( File::Spec->catfile( $path, '..', '..', 'foorum.yml' ) );
    if ( -e File::Spec->catfile( $path, '..', '..', 'foorum_local.yml' ) ) {
        my $extra_config
            = LoadFile( File::Spec->catfile( $path, '..', '..', 'foorum_local.yml' ) );
        $config = { %$config, %$extra_config };
    }

    return $config;
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

sub tt2 {

    return $tt2 if ($tt2);
    $config    = config()    unless ($config);
    $base_path = base_path() unless ($base_path);

    $tt2 = Template->new(
        {   INCLUDE_PATH => [ File::Spec->catdir( $base_path, 'templates' ) ],
            PRE_CHOMP    => 1,
            POST_CHOMP   => 1,
            STASH        => Template::Stash::XS->new,
        }
    );
    return $tt2;
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

1;
__END__

=pod

=head1 NAME

Foorum::XUtils - Utils for cron

=head1 FUNCTIONS

=over 4

=item base_path

the same as $c->config->{home} or $c->path_to

=item config

the same as $c->config expect ->{home}

=item cache

the same as $c->cache

=item tt2

generally like $c->view('TT'), yet a bit different

=item theschwartz

TheSchwartz->new with correct database from $config

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
