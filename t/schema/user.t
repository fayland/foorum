#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBI }
        or plan skip_all => "DBI is required for this test";
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 7;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema/;
my $schema = schema();

my $user_res = $schema->resultset('User');

# test get
my $user = $user_res->get( { user_id => 1 } );
isnt( $user, undef, 'get_one OK' );
is( $user->{user_id}, 1, 'get_one user_id OK' );

# test get_multi
my $users = $user_res->get_multi( user_id => [ 1, 2 ] );
is( scalar( keys %$users ), 2, 'get_multi OK' );
is( $users->{2}->{user_id}, 2, 'get_multi users.2.user_id OK' );

# test get_user_settings
my $settings = $user_res->get_user_settings($user);
is( $settings->{show_email_public}, 'N', 'get_user_settings show_email_public OK' );

# test real_update
my $org_email = $user->{email};
$user_res->real_update( $user, { email => 'a@a.com' } );

# test get_from_db
$user = $user_res->get_from_db( { user_id => 1 } );
is( $user->{email}, 'a@a.com', 'real_update OK' );

# data recover back
$user_res->real_update( $user, { email => $org_email } );
$user = $user_res->get( { user_id => 1 } );
is( $user->{email}, $org_email, 'real_update 2 OK' );

1;
