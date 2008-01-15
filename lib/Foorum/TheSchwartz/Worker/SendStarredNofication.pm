package Foorum::TheSchwartz::Worker::SendStarredNofication;

use strict;
use warnings;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema config base_path error_log tt2 cache/;
use Foorum::Adaptor::User;

my $user_model = new Foorum::Adaptor::User();

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my ($args) = $job->arg;
    my ( $object_type, $object_id, $from_id ) = @$args;

    my $schema    = schema();
    my $config    = config();
    my $cache     = cache();
    my $base_path = base_path();
    my $tt2       = tt2();

    # if it is a starred item and settings send_starred_notification is Y
    my $starred_rs = $schema->resultset('Star')->search(
        {   object_type => $object_type,
            object_id   => $object_id
        },
        { columns => ['user_id'], }
    );
    my @user_ids;
    while ( my $r = $starred_rs->next ) {
        push @user_ids, $r->user_id;
    }
    if ( scalar @user_ids ) {
        my $object = get_object( $schema, $cache, $object_type, $object_id );
        my $from = $user_model->get( { user_id => $from_id } );

        foreach my $user_id (@user_ids) {
            my $user = $user_model->get( { user_id => $user_id } );
            next unless ($user);
            next if ( $user->{user_id} == $from->{user_id} );    # skip himself
                                                                 # Send Notification Email
            send_mail(
                $schema, $tt2,
                $base_path,
                {   template => 'starred_notification',
                    to       => $user->{email},
                    lang     => $user->{lang},
                    stash    => {
                        c      => { config => $config, },
                        rept   => $user,
                        from   => $from,
                        object => $object,
                        base   => $config->{site}->{domain},
                    }
                }
            );
        }
    }

    $job->completed();
}

sub get_object {
    my ( $schema, $cache, $object_type, $object_id ) = @_;

    if ( $object_type eq 'topic' ) {
        my $object = $schema->resultset('Topic')->find( { topic_id => $object_id, } );
        return unless ($object);
        my $author = $user_model->get( { user_id => $object->author_id } );
        return {
            object_type => 'topic',
            object_id   => $object_id,
            title       => $object->title,
            author      => $author,
            url         => '/forum/' . $object->forum_id . "/$object_id",
            last_update => $object->last_update_date,
        };
    } elsif ( $object_type eq 'poll' ) {
        my $object = $schema->resultset('Poll')->find( { poll_id => $object_id, } );
        return unless ($object);
        my $author = $user_model->get( { user_id => $object->author_id } );
        return {
            object_type => 'poll',
            object_id   => $object_id,
            title       => $object->title,
            author      => $author,
            url         => '/forum/' . $object->forum_id . "/poll/$object_id",
            last_update => '-',
        };
    }
}

sub send_mail {
    my ( $schema, $tt2, $base_path, $opts ) = @_;

    my $lang = $opts->{lang};

    # find the template for TT use
    my $template_prefix;
    my $template_name = $opts->{template};
    my $file_prefix   = "$base_path/templates/lang/$lang/email/$template_name";
    if ( -e $file_prefix . '.txt' or -e $file_prefix . '.html' ) {
        $template_prefix = "lang/$lang/email/$template_name";
    } elsif ( $lang ne 'en' ) {

        # try to use lang=en for default
        $file_prefix = "$base_path/templates/lang/en/email/$template_name";
        if ( -e $file_prefix . '.txt' or -e $file_prefix . '.html' ) {
            $template_prefix = "lang/en/email/$template_name";
        }
    }
    unless ($template_prefix) {
        error_log( $schema, 'error',
            "Template not found in Email.pm notification with params: $template_name" );
        return 0;
    }

    # prepare the tt2
    my ( $plain_body, $html_body );

    my $stash  = $opts->{stash};
    my $config = $stash->{c}->{config};

    # prepare TXT format
    if ( -e $file_prefix . '.txt' ) {
        $tt2->process( $template_prefix . '.txt', $stash, \$plain_body );
    }
    if ( -e $file_prefix . '.html' ) {
        $tt2->process( $template_prefix . '.html', $stash, \$html_body );
    }

    # get the subject from $plain_body or $html_body
    # the format is ########Title Subject#########
    my $subject;
    if ( $plain_body and $plain_body =~ s/\#{6,}(.*?)\#{6,}\s+//isg ) {
        $subject = $1;
    }
    if ( $html_body and $html_body =~ s/\#{6,}(.*?)\#{6,}\s+//isg ) {
        $subject = $1;
    }
    $subject ||= 'Notification From ' . $config->{name};

    my $to         = $opts->{to};
    my $from       = $opts->{from} || $config->{mail}->{from_email};
    my $email_type = $opts->{email_type} || $opts->{template};
    $schema->resultset('ScheduledEmail')->create(
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
}

1;
