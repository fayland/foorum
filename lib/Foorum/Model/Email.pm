package Foorum::Model::Email;

use strict;
use warnings;
use base 'Catalyst::Model';
use Foorum::Utils qw/generate_random_word/;
use Foorum::ExternalUtils qw/theschwartz/;
use Data::Dumper;

sub send_activation {
    my ( $self, $c, $user, $new_email ) = @_;

    my $activation_code;
    my $rs = $c->model('DBIC')->resultset('UserActivation')
        ->find( { user_id => $user->user_id, } );
    if ($rs) {
        $activation_code = $rs->activation_code;
    } else {
        $activation_code = generate_random_word(10);
        my @extra_insert;
        if ($new_email) {
            @extra_insert = ( 'new_email', $new_email );
        }
        $c->model('DBIC')->resultset('UserActivation')->create(
            {   user_id         => $user->user_id,
                activation_code => $activation_code,
                @extra_insert,
            }
        );
    }

    my $email_body = $c->view('TT')->render(
        $c,
        $c->stash->{lang} . '/email/activation.html',
        {   no_wrapper      => 1,
            username        => $user->username,
            activation_code => $activation_code,
            new_email       => $new_email,
        }
    );

    $c->model('DBIC')->resultset('ScheduledEmail')->create(
        {   email_type => 'activation',
            from_email => $c->config->{mail}->{from_email},
            to_email   => $user->email,
            subject    => 'Your Activation Code In ' . $c->config->{name},
            plain_body => $email_body,
            time       => \'NOW()',
            processed  => 'N',
        }
    );
    my $client = theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');
}

sub send_forget_password {
    my ( $self, $c, $email, $username, $password ) = @_;

    my $email_body = $c->view('TT')->render(
        $c,
        $c->stash->{lang} . '/email/forget_password.html',
        {   no_wrapper => 1,
            username   => $username,
            password   => $password,
        }
    );

    $c->model('DBIC')->resultset('ScheduledEmail')->create(
        {   email_type => 'forget_password',
            from_email => $c->config->{mail}->{from_email},
            to_email   => $email,
            subject    => 'Your Password For '
                . $username . ' In '
                . $c->config->{name},
            plain_body => $email_body,
            time       => \'NOW()',
            processed  => 'N',
        }
    );
    my $client = theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
