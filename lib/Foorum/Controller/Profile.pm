package Foorum::Controller::Profile;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';
use Foorum::Utils qw/generate_random_word/;
use Foorum::XUtils qw/theschwartz/;
use Digest ();
use Locale::Country::Multilingual;
use vars qw/$lcm/;
$lcm = Locale::Country::Multilingual->new();

sub edit : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'user/profile/edit.html';

    # get all countries code
    $lcm->set_lang( $c->stash->{lang} );
    my @codes = $lcm->all_country_codes();
    my %countries;
    foreach (@codes) {
        $countries{$_} = $lcm->code2country($_);
    }
    $c->stash->{countries} = \%countries;

    unless ( $c->req->method eq 'POST' ) {
        my $birthday = $c->user->{details}->{birthday};
        if (    $birthday
            and $birthday
            and $birthday =~ /^(\d+)\-(\d+)\-(\d+)$/ ) {
            $c->stash(
                {   year  => $1,
                    month => $2,
                    day   => $3,
                }
            );
        }
        $c->stash->{user_details} = $c->user->{details};
        return;
    }

    my $birthday
        = $c->req->param('year') . '-'
        . $c->req->param('month') . '-'
        . $c->req->param('day');
    my ( @extra_valid, @extra_insert );
    if ( length($birthday) > 2 ) {    # is not --
        @extra_valid = ( { birthday => [ 'year', 'month', 'day' ] } => ['DATE'] );
        @extra_insert = ( birthday => $birthday );
    }

    # be compatible with Yahoo! ID and email
    foreach my $param ( 'gtalk', 'yahoo', 'skype' ) {
        if ( $c->req->param($param) =~ /^(\w+)\@/ ) {
            $c->req->param( $param, $1 );    # only need the username before @
        }
    }

    $c->form(
        gender => [ [ 'REGEX', qr/^(M|F)?$/ ] ],
        lang   => [ [ 'REGEX', qr/^\w{2}$/ ] ],
        @extra_valid,
        homepage => ['HTTP_URL'],
        nickname => [ qw/NOT_BLANK/, [qw/LENGTH 4 20/] ],
        'qq'     => [ [ 'REGEX', qr/^\d{6,14}$/ ] ],
        msn => [ qw/EMAIL_LOOSE/, [qw/LENGTH 5 64/] ],
        gtalk   => [ [ 'REGEX', qr/^\w{2,64}$/ ] ],
        yahoo   => [ [ 'REGEX', qr/^\w{2,64}$/ ] ],
        skype   => [ [ 'REGEX', qr/^\w{2,64}$/ ] ],
        country => [ [ 'REGEX', qr/^\w{2}$/ ] ],
    );
    return if ( $c->form->has_error );

    # validate country
    unless ( $lcm->code2country( $c->req->param('country') ) ) {
        $c->req->param( 'country', '' );
    }
    $c->model('DBIC::User')->update_user(
        $c->user,
        {   nickname => $c->req->param('nickname') || $c->user->username,
            gender   => $c->req->param('gender')   || 'NA',
            lang     => $c->req->param('lang')     || $c->config->{default_lang},
            country  => $c->req->param('country')  || '',
        }
    );

    $c->model('DBIC::UserDetails')->update_or_create(
        {   user_id  => $c->user->user_id,
            homepage => $c->req->param('homepage') || '',
            'qq'     => $c->req->param('qq') || '',
            msn      => $c->req->param('msn') || '',
            gtalk    => $c->req->param('gtalk') || '',
            yahoo    => $c->req->param('yahoo') || '',
            skype    => $c->req->param('skype') || '',
            @extra_insert,
        }
    );

    # clear user cache too
    $c->model('DBIC::User')->delete_cache_by_user( $c->user );

    $c->res->redirect( '/u/' . $c->user->username );
}

sub change_password : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'user/profile/change_password.html';

    return unless ( $c->req->method eq 'POST' );

    # check the password typed in is correct
    my $password = $c->req->param('password');
    my $d        = Digest->new( $c->config->{authentication}->{password_hash_type} );
    $d->add($password);
    my $computed = $d->digest;
    if ( $computed ne $c->user->{password} ) {
        $c->set_invalid_form( password => 'WRONG_PASSWORD' );
        return;
    }

    # execute validation.
    $c->form(
        new_password => [ qw/NOT_BLANK/, [qw/LENGTH 6 20/] ],
        { passwords => [ 'new_password', 'confirm_password' ] } => ['DUPLICATION'],
    );
    return if ( $c->form->has_error );

    # encrypted the new password
    my $new_password = $c->req->param('new_password');
    $d->reset;
    $d->add($new_password);
    my $new_computed = $d->digest;

    $c->model('DBIC::User')->update_user( $c->user, { password => $new_computed, } );

    $c->detach(
        '/print_message',
        [   {   msg          => 'OK',
                url          => '/profile/edit',
                stay_in_page => 1,
            }
        ]
    );
}

sub forget_password : Local {
    my ( $self, $c ) = @_;

    $c->detach( '/print_error', ['ERROR_EMAIL_OFF'] )
        unless ( $c->config->{mail}->{on} );

    $c->stash->{template} = 'user/profile/forget_password.html';
    return unless ( $c->req->method eq 'POST' );

    my $username = $c->req->param('username');
    my $email    = $c->req->param('email');

    my $user = $c->model('DBIC::User')->get( { username => $username } );
    return $c->stash->{ERROR_NOT_SUCH_USER} = 1 unless ($user);
    return $c->stash->{ERROR_NOT_MATCH} = 1 if ( $user->{email} ne $email );

    # create a random password
    my $random_password = &generate_random_word(8);
    my $d = Digest->new( $c->config->{authentication}->{password_hash_type} );
    $d->add($random_password);
    my $computed = $d->digest;

    # send email
    $c->model('DBIC::ScheduledEmail')->create_email(
        {   template => 'forget_password',
            to       => $email,
            lang     => $c->stash->{lang},
            stash    => {
                username => $username,
                password => $random_password
            }
        }
    );
    $c->model('DBIC::User')->update_user( $user, { password => $computed } );
    $c->detach(
        '/print_message',
        [   {   msg => 'Your Password is Sent to Your Email, Please have a check',
                url => '/login',
                stay_in_page => 1,
            }
        ]
    );
}

sub change_email : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'user/profile/change_email.html';

    return unless ( $c->req->method eq 'POST' );

    # check the password typed in is correct
    my $password = $c->req->param('password');
    my $d        = Digest->new( $c->config->{authentication}->{password_hash_type} );
    $d->add($password);
    my $computed = $d->digest;
    if ( $computed ne $c->user->{password} ) {
        $c->set_invalid_form( password => 'WRONG_PASSWORD' );
        return;
    }

    # validation
    my $email = $c->req->param('email');
    if ( $email eq $c->user->email ) {
        return $c->set_invalid_form( email => 'EMAIL_DUPLICATION' );
    }
    my $err = $c->model('Validation')->validate_email( $c, $email );
    if ($err) {
        return $c->set_invalid_form( email => $err );
    }

    if ( $c->config->{mail}->{on} and $c->config->{register}->{activation} ) {

        # send activation code
        $c->model('DBIC::ScheduledEmail')
            ->send_activation( $c->user, $email, { lang => $c->stash->{lang} } );
        $c->res->redirect( '/register/activation/' . $c->user->username );
    } else {
        $c->model('DBIC::User')->update_user( $c->user, { email => $email, } );
        $c->res->redirect('/profile/edit');
    }
}

sub change_username : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'user/profile/change_username.html';

    return unless ( $c->req->method eq 'POST' );

    # check the password typed in is correct
    my $password = $c->req->param('password');
    my $d        = Digest->new( $c->config->{authentication}->{password_hash_type} );
    $d->add($password);
    my $computed = $d->digest;
    if ( $computed ne $c->user->{password} ) {
        $c->set_invalid_form( password => 'WRONG_PASSWORD' );
        return;
    }

    # execute validation.
    $c->form(
        new_username => [qw/NOT_BLANK/],
        { usernames => [ 'new_username', 'confirm_username' ] } => ['DUPLICATION'],
    );
    return if ( $c->form->has_error );

    my $new_username = $c->req->param('new_username');
    my $err = $c->model('Validation')->validate_username( $c, $new_username );
    if ($err) {
        $c->set_invalid_form( new_username => $err );
        return;
    }

    $c->model('DBIC::User')->update_user( $c->user, { username => $new_username, } );
    $c->session->{__user} = $new_username;

    $c->res->redirect("/u/$new_username");
}

sub profile_photo : Local {
    my ( $self, $c ) = @_;

    return $c->res->redirect('/login') unless ( $c->user_exists );

    $c->stash->{template} = 'user/profile/profile_photo.html';

    return unless ( $c->req->method eq 'POST' );

    my $new_upload = $c->req->upload('upload');
    my $old_upload_id
        = ( $c->user->{profile_photo}->{type} eq 'upload' )
        ? $c->user->{profile_photo}->{value}
        : 0;
    my $new_upload_id = $old_upload_id;
    if ( ( $c->req->param('attachment_action') eq 'delete' ) or $new_upload ) {

        # delete old upload
        if ($old_upload_id) {
            $c->model('DBIC::Upload')
                ->remove_by_upload( $c->user->{profile_photo}->{upload} );
            $new_upload_id = 0;
        }

        # add new upload
        if ($new_upload) {
            $new_upload_id = $c->model('DBIC::Upload')
                ->add_file( $new_upload, { user_id => $c->user->user_id } );
            unless ( $new_upload_id =~ /^\d+$/ ) {
                return $c->set_invalid_form( upload => $new_upload_id );
            }

            my $client = theschwartz();
            $client->insert( 'Foorum::TheSchwartz::Worker::ResizeProfilePhoto',
                $new_upload_id );
        }
    }

    $c->model('DBIC')->resultset('UserProfilePhoto')
        ->search( { user_id => $c->user->{user_id} } )->delete;
    $c->model('DBIC')->resultset('UserProfilePhoto')->create(
        {   user_id => $c->user->{user_id},
            type    => 'upload',
            value   => $new_upload_id,
            width   => 0,
            height  => 0,
            time    => time(),
        }
    );

    $c->model('DBIC::User')->delete_cache_by_user( $c->user );

    $c->res->redirect( '/u/' . $c->user->{username} );
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
