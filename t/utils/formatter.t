use strict;
use warnings;
use Test::More tests => 4;

use Foorum::Formatter qw/filter_format/;

my $html = filter_format(' :inlove: [b]Test[/b] [size=14]dsadsad[/size] [url=http://fayland/]da[/url]', { format => 'ubb' } );

like($html, qr/inlove.gif/, 'emot convert OK');
like($html, qr/\<a href/,   '[url] convert OK');
like($html, qr/bold/,       '[b] convert OK');
like($html, qr/14px/,       '[size] convert OK');