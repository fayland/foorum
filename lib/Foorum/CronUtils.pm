package Foorum::CronUtils;

use strict;
use warnings;

use Foorum::Version; our $VERSION = $Foorum::VERSION;

use YAML::XS qw/LoadFile/;    # config
use File::Spec;
use MooseX::TheSchwartz;      # theschwartz
use DBI;
use base 'Exporter';
use vars qw/@EXPORT_OK $cron_config/;
@EXPORT_OK = qw/ theschwartz cron_config /;
use Foorum::XUtils qw/config base_path/;

sub theschwartz {

    my $config = config();
    my $dbh    = DBI->connect_cached(
        $config->{theschwartz_dsn},
        $config->{theschwartz_user} || $config->{dsn_user},
        $config->{theschwartz_pwd}  || $config->{dsn_pwd},
        { PrintError => 1, RaiseError => 1 }
    );
    my $theschwartz = MooseX::TheSchwartz->new( databases => [$dbh] );

    return $theschwartz;
}

sub cron_config {

    return $cron_config if ($cron_config);

    my $base_path = base_path();
    $cron_config = LoadFile( File::Spec->catfile( $base_path, 'conf', 'cron.yml' ) );

    return $cron_config;
}

1;
__END__

