package Foorum::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2008-01-03 14:28:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m3FmejXtIfNVf4NlbP0o4g


# You can replace this text with custom content, and it will be preserved on regeneration
use vars qw/$VERSION/;
$VERSION = '0.01';

# XXX?
# Need rework later.

use YAML qw/LoadFile/;    # config
use vars qw/$config $cache/;

use File::Spec;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);

sub config {
    return $config if ($config);

    $config = LoadFile("$path/../../foorum.yml");
    my $extra_config = LoadFile("$path/../../foorum_local.yml");
    $config = { %$config, %$extra_config };
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

sub connect {
    my $s = shift->SUPER::connect(@_);
    $s->storage->sql_maker->quote_char('`');
    $s->storage->sql_maker->name_sep('.');
    return $s;
}

1;
