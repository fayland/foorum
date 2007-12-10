package Foorum::Controller::Logon;

use strict;
use warnings;
use base 'Catalyst::Controller';

sub login : Global {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/forum') if ( $c->user_exists );

    $c->stash->{template} = 'user/login.html';
    my $url_base = $c->req->base;
    $c->req->param( 'referer', $c->req->referer )
        if (not $c->req->param('referer')
        and $c->req->referer =~ /$url_base/
        and $c->req->referer !~ /login/ );
    return unless ( $c->req->method eq 'POST' );

    my $username = $c->req->param('username');
    $username =~ s/\W+//isg;
    my $email    = $c->req->param('email');
    if (not $username and $email) {
        my $user = $c->model('User')->get($c, { email => $email } );
        if ($user) {
            $username = $user->{username};
        } else {
            return $c->stash->{error} = 'ERROR_AUTH_FAILED';
        }
    }

    # check if we need captcha
    # for login password wrong more than 3 times, we create a captcha.
    my $mem_key             = "captcha|login|username=$username";
    my $failure_login_times = $c->cache->get($mem_key);

    if ( $username and my $password = $c->req->param('password') ) {

        my $can_login  = 0;
        my $captcha_ok = ( $failure_login_times > 2
                and $c->validate_captcha( $c->req->param('captcha') ) );
        $can_login = ( $failure_login_times < 3 or $captcha_ok );

        if ( $can_login and $c->authenticate( { username => $username, password => $password } ) ) {
            # check if he is activated
            if (    $c->config->{mail}->{on}
                and $c->config->{register}->{activation}
                and $c->user->get('status') eq 'unverified' )
            {
                my $username = $c->user->username;
                $c->logout;
                return $c->res->redirect("/register/activation/$username");
            }
            
            if ($c->user->get('status') eq 'banned' or $c->user->get('status') eq 'blocked') {
                $c->logout;
                $c->detach('/print_error', [ 'ERROR_ACCOUNT_CLOSED_STATUS' ] );
            }

            # remember me
            if ( $c->req->param('remember_me') ) {
                $c->session_time_to_live(604800);  # 7 days = 24 * 60 * 60 * 7
            }

            # login_times++
            $c->model('User')->update(
                $c,
                $c->user,
                {   login_times   => \'login_times + 1',
                    last_login_on => \'NOW()',
                    last_login_ip => $c->req->address,
                }
            );

            if ( length( $c->user->lang ) == 2 ) {
                $c->res->cookies->{lang} = { value => $c->user->lang };
                $c->stash->{lang} = $c->user->lang;
            }

            # redirect
            my $referer = $c->req->param('referer') || '/';
            $c->res->redirect($referer);
        } else {
            $failure_login_times = 0 unless ($failure_login_times);
            $failure_login_times++;
            $c->cache->set( $mem_key, $failure_login_times, 600 ); # 10 minite
            $c->stash->{failure_login_times} = $failure_login_times;

            if ($can_login) {
                $c->stash->{error} = 'ERROR_AUTH_FAILED';
            } else {
                $c->stash->{error} = 'ERROR_CAPTCHA';
            }
        }
    } else {
        $c->stash->{error} = 'ERROR_ALL_REQUIRED';
    }
}

sub logout : Global {
    my ( $self, $c ) = @_;

    # log the user out
    $c->logout;

    $c->res->redirect('/');
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
