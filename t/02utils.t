use strict;
use warnings;
use Test::More tests => 1;

use Foorum::Utils qw/datetime_to_tt2_acceptable/;

my $datetime = '2007-12-21 08:09:01';
my $ret = datetime_to_tt2_acceptable($datetime);

is($ret, '8:9:1 21/12/2007', 'datetime_to_tt2_acceptable OK');