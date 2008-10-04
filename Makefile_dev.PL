use inc::Module::Install;

name            ('Foorum');
author          ('Fayland Lam<fayland@gmail.com>');
abstract        ('Foorum - forum system based on Catalyst');
license         ('perl');
version_from    ('lib/Foorum/Version.pm');

requires 'Template' => '2.20';
requires 'DBIx::Class';
requires 'Catalyst' => '5.64';
requires 'Moose'    => '0.57';
requires 'Digest';
requires 'DateTime';
requires 'Date::Calc';
requires 'Encode::Guess';
requires 'File::Path';
requires 'File::Copy';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Config::YAML::XS';
requires 'Cache::FileCache';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::PageCache' => '0.21';
requires 'Set::Object';
requires 'Catalyst::Plugin::Authentication' => '0.10004';
requires 'Catalyst::Plugin::Authentication::Credential::Password';
requires 'Catalyst::Authentication::Store::FromSub::Hash' => '0.06';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::Delegate'; # for DBIC next line
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::Session::DynamicExpiry';
requires 'Catalyst::Plugin::FormValidator::Simple';
requires 'Catalyst::Plugin::Captcha';
requires 'Catalyst::Plugin::I18N' => '0.08';
requires 'Template::Plugin::FillInForm';
requires 'Template::Plugin::Date';
requires 'File::Remove';
requires 'HTML::Email::Obfuscate';
requires 'Locale::Country::Multilingual' => '0.03'; # for tw lang
#requires 'File::Slurp';
requires 'Net::IP::Match::Regexp';
requires 'Net::CIDR::Lite';
requires 'WWW::Contact';

# search
requires 'Sphinx::Search';

# cron
requires 'MooseX::TheSchwartz';
requires 'Schedule::Cron';
if ($^O ne 'MSWin32') {
    recommends 'Proc::PID::File';
}
requires 'File::HomeDir';

# cron/misc|db
requires 'File::Next';
requires 'CSS::Minifier';
requires 'JavaScript::Minifier';
requires 'Encode::HanConvert';
requires 'Perl::Critic';
requires 'Perl::Tidy';
requires 'SQL::Translator';
requires 'DBICx:::AutoDoc';
requires 'Pod::From::GoogleWiki' => '0.05';

# mail
requires 'MIME::Entity';
requires 'Email::Send';
recommends 'Email::Send::SMTP::TLS';

# formatter
requires 'Text::Textile';
requires 'URI::Find::UTF8';
requires 'Text::GooglewikiFormat' => '0.04';

# db debug
requires 'Catalyst::Model::DBIC::Schema::QueryLog';

tests ( join ' ', ( glob('t/*.t'), glob('t/*/*.t') ) );

catalyst;

#install_script glob('script/*.pl');
auto_install;
WriteAll;
