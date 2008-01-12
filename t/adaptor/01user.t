use strict;
use warnings;
use Test::More;
use Foorum::Adaptor::User;

BEGIN {

    $ENV{Adaptor_TEST} or plan skip_all => "set ENV{Adaptor_TEST} for this test";

    plan tests => 4;
}

my $user_model = new Foorum::Adaptor::User();
my $user = $user_model->get( { user_id => 1 } );
isnt($user, undef, 'get OK');
is($user->{user_id}, 1, 'get user_id OK');

my $users = $user_model->get_multi( user_id => [1, 2] );
is(scalar(keys %$users), 2, 'get_multi OK');
is($users->{2}->{user_id}, 2, 'get_multi users.2.user_id OK');

#use Data::Dumper;
#diag(Dumper(\$users));