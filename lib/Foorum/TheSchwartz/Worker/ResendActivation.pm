package Foorum::TheSchwartz::Worker::ResendActivation;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/config base_path cache/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my $schema    = schema();
    my $config    = config();
    my $cache     = cache();
    my $base_path = base_path();

    # resend the emails if user is not verified after 30 days of the registration time
    my $rs = $schema->resultset('User')->search(
        {   status        => 'unverified',
            register_time => { '<', time() - 30 * 86400 }
        }
    );

    my @all_user_ids;
    while ( my $user = $rs->next ) {

        # send activation code
        $c->model('DBIC::ScheduledEmail')
            ->send_activation( $user, 0, { lang => $user->lang } );
        push @all_user_ids, $user->user_id;
    }

    # XXX? TODO, "remove unverfied data after half a year of the registration time."

    my $log_user_ids = join( ', ', @all_user_ids );
    error_log( $schema, 'info', <<LOG);
ResendActivation - $log_user_ids
LOG

    $job->completed();
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::ResendActivation - resend activation email to unverified users everyday

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

After user registered, they don't verified the emails for some reasons.
so there are lots of unverified users, that's not so wise to keep the data of those unverified users.
This module is aim to resend the activation emails and remove unverfied data after half a year of the registration time.

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
