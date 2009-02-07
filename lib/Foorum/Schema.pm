package Foorum::Schema;

use strict;
use warnings;
our $VERSION = '1.000002';
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;

use Foorum::XUtils ();

sub base_path {
    return Foorum::XUtils::base_path();
}

sub config {
    return Foorum::XUtils::config();
}

sub cache {
    return Foorum::XUtils::cache();
}

sub theschwartz {
    return Foorum::XUtils::theschwartz();
}

sub tt2 {
    return Foorum::XUtils::tt2();
}

sub connect {
    my $s = shift->SUPER::connect(@_);
    $s->storage->sql_maker->quote_char('`');
    $s->storage->sql_maker->name_sep('.');
    return $s;
}

1;
