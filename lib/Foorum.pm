package Foorum;

use strict;
use warnings;

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Cache::Memcached
    Authentication
    Session::DynamicExpiry
    Session
    Session::Store::DBIC
    Session::State::Cookie
    I18N
    PageCacheWithI18N
    FormValidator::Simple
    Captcha
    FoorumUtils
    /;

#

use vars qw/$VERSION/;
$VERSION = '0.1.0';

__PACKAGE__->config( { VERSION => $VERSION } );

__PACKAGE__->setup();

__PACKAGE__->log->levels( 'error', 'fatal' );    # for real server
if ( __PACKAGE__->config->{debug_mode} ) {
    __PACKAGE__->log->enable( 'debug', 'info', 'warn' )
        ;                                        # for developer server
    {
        # these code are copied from Catalyst.pm setup_log
        no strict 'refs';
        my $class = __PACKAGE__;
        *{"$class\::debug"} = sub {1};
    }

    #my @extra_plugins = qw/ StackTrace /;
    #__PACKAGE__->setup_plugins( [@extra_plugins] );
}

1;
__END__

=head1 NAME

Foorum - forum system based on Catalyst

=head1 DESCRIPTION

nothing for now.

=head1 FEATURES

=over 4

=item open source

u can FETCH all code from L<http://fayland.googlecode.com/svn/trunk/Foorum/> any time any where.

=item Win32 compatibility

Linux/Unix/Win32 both OK.

=item templates

use L<Template>; for UI.

=item built-in cache

use L<Cache::Memcached>;

=item reliable job queue

use L<TheSchwartz>;

=item Captcha

To keep robot out.

=back

=head1 SEE ALSO

L<Catalyst::Runtime>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
