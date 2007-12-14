#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";

use Foorum::Model::DBIC;
use Foorum::Schema;

# demonstrate picking up database connection info
my $connect_info = Foorum::Model::DBIC->config->{connect_info};
print "connecting schema to ".$connect_info->[0]."\n";

my $schema = Foorum::Schema->connect( @$connect_info );

# show the model classes available
my @sources = $schema->sources();
print 'found schema model sources :-  ' . join(", ",@sources) . "\n";

1;