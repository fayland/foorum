package t::theschwartz::TestTheSchwartz;

use strict;
use warnings;
use base qw/Exporter/;
use Test::More;
use FindBin qw/$Bin/;
use DBI;
our @EXPORT = (@Test::More::EXPORT, 'run_test');

eval 'require DBD::SQLite';
plan skip_all => 'this test requires DBD::SQLite' if $@;
eval 'require File::Temp';
plan skip_all => 'this test requires File::Temp' if $@;
eval 'require MooseX::TheSchwartz;';
plan skip_all => 'this test requires MooseX::TheSchwartz' if $@;

sub run_test (&) {
    my $code = shift;
    my $db_file = File::Spec->catfile( $Bin, '..', 'lib', 'Foorum', 'theschwartz.db' );
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {RaiseError => 1}) or die $DBI::err;

    # work around for DBD::SQLite's resource leak
    tie my %blackhole, 't::theschwartz::TestTheSchwartz::Blackhole';
    $dbh->{CachedKids} = \%blackhole;

    $code->($dbh); # do test

    $dbh->disconnect;
}

{
    package t::theschwartz::TestTheSchwartz::Blackhole;
    use base qw/Tie::Hash/;
    sub TIEHASH { bless {}, shift }
    sub STORE { } # nop
    sub FETCH { } # nop
}

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
1;

