#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 11;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache base_path/;
use Foorum::Utils qw/encodeHTML/;
my $schema = schema();
my $cache  = cache();

my $topic_res = $schema->resultset('Topic');

my $create = {
    topic_id => 1,
    forum_id => 1,
    title    => 'test title',
    closed   => 0,
    author_id => 1,
    last_updator_id  => 1,
    last_update_date => \'CURRENT_TIMESTAMP', # For SQLite
};

# test create topic
$cache->remove("topic|topic_id=1");
$topic_res->create_topic($create);
my $starred = $schema->resultset('Star')->count(
    {   user_id     => 1,
        object_type => 'topic',
        object_id   => 1,
    }
);
is($starred, 1, 'has Star record');

# test get
my $topic = $topic_res->get(1);
is($topic->{forum_id}, 1, 'get forum_id OK');
is($topic->{title}, 'test title', 'get title OK');
is($topic->{author_id}, 1, 'get author_id OK');

# test update_topic
$topic_res->update_topic(1, { title => 'test title2', author_id => 2 } );
$topic = $topic_res->get(1);
is($topic->{title}, 'test title2', 'get title OK after update_topic');
is($topic->{author_id}, 2, 'get author_id OK after update_topic');

# be Sure forum is there before remove topic
$schema->resultset('Forum')->create( {
    forum_id => 1,
    forum_code => 'test1111',
    name    => 'FoorumTest',
    description => 'desc',
    forum_type  => 'classical',
    policy => 'public',
    total_members => 1,
    total_topics  => 7,
    total_replies => 1,
} );
# test remove
$topic_res->remove(1, 1, { operator_id => 2, log_text => 'delete for test', SQLite_NOW => \'CURRENT_TIMESTAMP' } );

$starred = $schema->resultset('Star')->count(
    {   user_id     => 1,
        object_type => 'topic',
        object_id   => 1,
    }
);
is($starred, 0, 'no Star record after remove');
$topic = $topic_res->get(1);
is($topic, undef, 'topic is undef after remove');
my $log_action = $schema->resultset('LogAction')->search( {
    action      => 'delete',
    object_type => 'topic',
    object_id   => 1,
} )->first;
isnt($log_action, undef, 'has LogAction record');
is($log_action->user_id, 2, 'operator_id OK');
is($log_action->text, 'delete for test', 'LogAction reason OK');

END {
    my $base_path = base_path();
    File::Copy::copy( "$base_path/t/lib/Foorum/backup.db",
        "$base_path/t/lib/Foorum/test.db" );
}

1;