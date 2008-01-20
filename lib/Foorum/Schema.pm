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
