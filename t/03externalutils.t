use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw/$RealBin/;
use Cwd qw/abs_path/;
use Foorum::ExternalUtils qw/base_path/;

my $base_path = base_path();
my $real = abs_path("$RealBin/../");

is($base_path, $real, 'abs_path OK');
#diag($base_path);