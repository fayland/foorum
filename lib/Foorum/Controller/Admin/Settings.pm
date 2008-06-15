package Foorum::Controller::Admin::Settings;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';
use YAML qw/DumpFile LoadFile/;

sub auto : Private {
    my ( $self, $c ) = @_;

    # only administrator is allowed. site moderator is not allowed here
    unless ( $c->model('Policy')->is_admin( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'admin/settings/index.html';
    if ( $c->req->method ne 'POST' ) {

        # for FillInForm
        my $fulfill = {
            maintain     => $c->config->{function_on}->{maintain},
            register     => $c->config->{function_on}->{register},
            create_forum => $c->config->{function_on}->{create_forum},

            site_domain => $c->config->{site}->{domain},

            message_per_page => $c->config->{per_page}->{message},
            forum_per_page   => $c->config->{per_page}->{forum},
            topic_per_page   => $c->config->{per_page}->{topic},

            most_deletion_topic => $c->config->{per_day}->{most_deletion_topic},

        };
        $c->stash->{fulfill} = $fulfill;
        return;
    }

    my $yaml;
    my $local_yml = $c->path_to('foorum_local.yml');
    if ( -e $local_yml ) {
        $yaml = LoadFile($local_yml);
    }

    my $params = $c->req->params;
    my %params = %$params;

    # Site
    my $domain = $params{site_domain};
    $domain = $c->req->base unless ($domain);
    $domain .= '/';
    $domain =~ s/\/+$/\//isg;
    $yaml->{site}->{domain} = $domain;

    # function on
    my $maintain = $params{maintain};
    $maintain = 0 if ( $maintain != 1 );
    my $register = $params{register};
    $register = 1 if ( $register != 0 );
    my $activation = $params{activation};
    $activation = 1 if ( $activation != 0 );
    my $create_forum = $params{create_forum};
    $create_forum = 1 if ( $create_forum != 0 );
    $yaml->{function_on} = {
        %{ $c->config->{function_on} },    # keep some values
        activation   => $activation,
        maintain     => $maintain,
        register     => $register,
        create_forum => $create_forum
    };

    # per page
    my $message_per_page = $params{message_per_page};
    $message_per_page = 8 if ( $message_per_page !~ /^\d+$/ );
    my $forum_per_page = $params{forum_per_page};
    $forum_per_page = 20 if ( $forum_per_page !~ /^\d+$/ );
    my $topic_per_page = $params{topic_per_page};
    $topic_per_page = 10 if ( $topic_per_page !~ /^\d+$/ );
    $yaml->{per_page} = {
        message => $message_per_page || 8,    # || 8 here is in case that's 0
        forum   => $forum_per_page   || 20,
        topic   => $topic_per_page   || 10
    };

    # per day
    my $most_deletion_topic = $params{most_deletion_topic};
    $most_deletion_topic = 5 if ( $most_deletion_topic !~ /^\d+$/ );
    $yaml->{per_day} = { most_deletion_topic => $most_deletion_topic || 5 };

    $c->config($yaml);                        # load in live

    DumpFile( $local_yml, $yaml );
    $c->stash->{thanks} = 1;
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
