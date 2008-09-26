package t::theschwartz::Redefined;

use strict;
use warnings;

{
    package Foorum::SUtils;
    
    use Foorum::TestUtils ();
    sub schema { Foorum::TestUtils::schema() }
    
    1;
}
{
    package Foorum::XUtils;
    
    use Carp qw/croak/;
    use Foorum::TestUtils ();
    sub config { Foorum::TestUtils::config(); }
    sub cache  { Foorum::TestUtils::cache(); }
    sub theschwartz { croak 'undefined'; }
    
    1;
}