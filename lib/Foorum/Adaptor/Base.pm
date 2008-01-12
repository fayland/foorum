package Foorum::Adaptor::Base;

use strict;
use warnings;
use YAML qw/LoadFile/;    # config
use Foorum::Schema;       # schema
use TheSchwartz;          # theschwartz
use Template;             # template
use Template::Stash::XS;
use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub new {
    my $self = shift;
    
    my $params = {};
    return bless $params => $self;
}

sub base_path {
    my $self = shift;
    
    return $self->{path} if ( $self->{path} );
    $self->{path} = abs_path("$path/../../../");
    
    return $self->{path};
}

sub config {
    my $self = shift;

    return $self->{config} if ($self->{config});

    my $config = LoadFile("$path/../../../foorum.yml");
    my $extra_config = LoadFile("$path/../../../foorum_local.yml");
    $config = { %$config, %$extra_config };
    $self->{config} = $config;
    return $self->{config};
}

sub schema {
    my $self = shift;

    return $self->{schema} if ($self->{schema});
    my $config = $self->config();

    $self->{schema}
        = Foorum::Schema->connect( $config->{dsn}, $config->{dsn_user},
        $config->{dsn_pwd}, { AutoCommit => 1, RaiseError => 1, PrintError => 1 },
        );
    return $self->{schema};
}

*default_cache_backend = \&cache;
sub cache {
    my $self = shift;

    return $self->{cache} if ($self->{cache});
    my $config = $self->config();

    my %params = %{ $config->{cache}{backends}{default} };
    my $class  = delete $params{class};

    eval("use $class;");    ## no critic (ProhibitStringyEval)
    unless ($@) {
        $self->{cache} = $class->new( \%params );
    }

    return $self->{cache};
}

sub theschwartz {
    my $self = shift;

    return $self->{theschwartz} if ($self->{theschwartz});
    my $config = $self->config();

    $self->{theschwartz} = TheSchwartz->new(
        databases => [
            {   dsn  => $config->{theschwartz_dsn},
                user => $config->{theschwartz_user} || $config->{dsn_user},
                pass => $config->{theschwartz_pwd} || $config->{dsn_pwd},
            }
        ],
        verbose => 0,
    );

    return $self->{theschwartz};
}

sub tt2 {
    my $self = shift;

    return $self->{tt2} if ($self->{tt2});
    my $config = $self->config();

    $self->{tt2} = Template->new(
        {   INCLUDE_PATH => ["$path/../../../templates"],
            PRE_CHOMP    => 1,
            POST_CHOMP   => 1,
            STASH        => Template::Stash::XS->new,
        }
    );
    return $self->{tt2};
}

sub error_log {
    my ( $self, $level, $text ) = @_;

    return unless ($text);
    
    my $schema = $self->schema();
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

Foorum::Adaptor::Base - base module

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
