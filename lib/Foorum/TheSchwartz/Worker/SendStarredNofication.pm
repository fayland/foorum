package Foorum::TheSchwartz::Worker::SendStarredNofication;

use strict;
use warnings;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema config/;
use Foorum;

my $c = Foorum->prepare();

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my ($args) = $job->arg;
    my ($object_type, $object_id, $from_id) = @$args;

    my $schema = schema();
    my $config = config();

    # if it is a starred item and settings send_starred_notification is Y
    my $starred_rs = $schema->resultset('Star')->search( {
        object_type => $object_type,
        object_id   => $object_id
    }, {
        columns => ['user_id'],
    } );
    my @user_ids;
    while (my $r = $starred_rs->next) {
        push @user_ids, $r->user_id;
    }
    if (scalar @user_ids) {
        my $object = $c->model('Object')->get_object_by_type_id($c, { object_id => $object_id, object_type => $object_type } );
        my $from   = $c->model('User')->get($c, { user_id => $from_id } );
        
        foreach my $user_id (@user_ids) {
            my $user = $c->model('User')->get($c, { user_id => $user_id } );
            next unless ($user);
            # Send Notification Email
            $c->model('Email')->create(
                $c,
                {   template => 'starred_notification',
                    to       => $user->{email},
                    stash    => {
                        rept    => $user,
                        from    => $from,
                        object  => $object,
                        host    => $config->{site}->{domain},
                    }
                }
            );
        }
    }

    $job->completed();
}

1;
