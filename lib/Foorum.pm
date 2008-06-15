package Foorum;

use strict;
use warnings;

use Catalyst qw/
    Config::YAML
    Static::Simple
    Authentication
    Cache
    Session::DynamicExpiry
    Session
    Session::Store::DBIC
    Session::State::Cookie
    I18N
    FormValidator::Simple
    Captcha
    +Foorum::Plugin::FoorumUtils
    /;

use Foorum::Version; our $VERSION = $Foorum::VERSION;

__PACKAGE__->config( { VERSION => $VERSION } );
__PACKAGE__->config( 'config_file' => [ 'foorum.yml', 'foorum_local.yml' ] );

__PACKAGE__->setup();

if ( __PACKAGE__->config->{function_on}->{page_cache} ) {
    __PACKAGE__->setup_plugins( ['PageCache'] );
} else {
    {
        no strict 'refs';    ## no critic (ProhibitNoStrict)
        my $class = __PACKAGE__;
        *{"$class\::cache_page"}        = sub {1};
        *{"$class\::clear_cached_page"} = sub {1};
    }
}

{
    use Sub::Install;

    # rewrite _get_page_cache_key in C::A::PageCache for own use
    my $_get_page_cache_key = sub {
        my $c = shift;

        # We can't rely on the params after the user's code has run, so
        # use the key created during the initial dispatch phase
        return $c->_page_cache_key if ( $c->_page_cache_key );

        my $key = "/" . $c->req->path;

        # Change Start
        my $lang;
        $lang = $c->req->cookie('lang')->value if ( $c->req->cookie('lang') );
        $lang ||= $c->user->lang if ( $c->user_exists );
        $lang ||= $c->config->{default_lang};
        $lang = $c->req->param('lang') if ( $c->req->param('lang') );
        $lang =~ s/\W+//isg;
        $key .= ':' . $lang;

        # Change End

        if ( scalar $c->req->param ) {
            my @params;
            foreach my $arg ( sort keys %{ $c->req->params } ) {
                if ( ref $c->req->params->{$arg} ) {
                    my $list = $c->req->params->{$arg};
                    push @params, map { "$arg=" . $_ } sort @{$list};
                } else {
                    push @params, "$arg=" . $c->req->params->{$arg};
                }
            }
            $key .= '?' . join( '&', @params );
        } elsif ( my $query = $c->req->uri->query ) {
            $key .= '?' . $query;
        }

        $c->_page_cache_key($key);

        return $key;
    };
    Sub::Install::install_sub(
        {   code => $_get_page_cache_key,
            into => 'Catalyst::Plugin::PageCache',
            as   => '_get_page_cache_key'
        }
    );
}

1;
__END__

=head1 NAME

Foorum - forum system based on Catalyst

=head1 DESCRIPTION

nothing for now.

=head1 LIVE DEMO

L<http://www.foorumbbs.com/>

=head1 FEATURES

=over 4

=item open source

u can FETCH all code from L<http://foorum.googlecode.com/svn/trunk/> any time any where.

=item Win32 compatibility

Linux/Unix/Win32 both OK.

=item templates

use L<Template> for UI.

=item built-in cache

use L<Cache::Memcached> or use L<Cache::FileCache> or others;

=item reliable job queue

use L<TheSchwartz>

=item Multi Formatter

L<HTML::BBCode>, L<Text::Textile>, L<Pod::Xhtml>, L<Text::GooglewikiFormat>

=item Captcha

To keep robot out.

=back

=head1 JOIN US

please send me an email to add u into the google.code Project members list.

=head1 TODO

L<http://code.google.com/p/foorum/issues/list>

=head1 SEE ALSO

L<Catalyst>, L<DBIx::Class>, L<Template>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
