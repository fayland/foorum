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
        'lang/' . $c->stash->{lang} . '/email/activation.html',
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

sub create {
    my ($self, $c, $opts) = @_;
    
    # find the template for TT use
    my $template_prefix;
    my $template_name = $opts->{template};
    my $file_prefix = $c->path_to( 'templates', 'lang', $c->stash->{lang}, 'email', $template_name )->stringify;
    if (-e $file_prefix . '.txt' or -e $file_prefix . '.html') {
        $template_prefix = 'lang/' . $c->stash->{lang} . '/email/' . $template_name;
    } elsif ($c->stash->{lang} ne 'en') {
        # try to use lang=en for default
        $file_prefix = $c->path_to( 'templates', 'lang', 'en', 'email', $template_name )->stringify;
        if (-e $file_prefix . '.txt' or -e $file_prefix . '.html') {
            $template_prefix = 'lang/en/email/' . $template_name;
        }
    }
    unless ($template_prefix) {
        $c->model('Log')->log_error($c, 'error', "Template not found in Email.pm notification with params: $template_name");
        return 0;
    }
    
    # prepare the tt2
    my ($plain_body, $html_body);
    my $stash = $opts->{stash} || {};
    $stash->{c} = $c; # add $c to tt2
    $stash->{base} = $c->req->base;
    $stash->{no_wrapper} = 1;
    
    # prepare TXT format
    if (-e $file_prefix . '.txt') {
        $plain_body = $c->view('TT')->render( $c, $template_prefix . '.txt', $stash);
    }
    if (-e $file_prefix . '.html') {
        $html_body = $c->view('TT')->render( $c, $template_prefix . '.html', $stash);
    }
    # get the subject from $plain_body or $html_body
    # the format is ########Title Subject#########
    my $subject;
    if ($plain_body and $plain_body =~ /\#{6,}(.*?)\#{6,}\n+/isg) {
        $subject = $1;
        $plain_body =~ s/\#{6,}(.*?)\#{6,}\n+//isg;
    }
    if ($html_body and $html_body =~ /\#{6,}(.*?)\#{6,}\n+/isg) {
        $subject = $1;
        $html_body =~ s/\#{6,}(.*?)\#{6,}\n+//isg;
    }
    $subject ||= 'Notification From ' . $c->config->{name};
    
    my $to = $opts->{to};
    my $from = $opts->{from} || $c->config->{mail}->{from_email};
    my $email_type = $opts->{email_type} || $opts->{template};
    $c->model('DBIC')->resultset('ScheduledEmail')->create(
        {   email_type => $email_type,
            from_email => $from,
            to_email   => $to,
            subject    => $subject,
            plain_body => $plain_body,
            html_body  => $html_body,
            time       => \'NOW()',
            processed  => 'N',
        }
    );
    
    my $client = theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');
    
    return 1;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
