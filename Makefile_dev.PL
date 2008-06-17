use inc::Module::Install;

name            ('Foorum');
author          ('Fayland Lam<fayland@gmail.com>');
abstract        ('Foorum - forum system based on Catalyst');
license         ('perl');
version_from    ('lib/Foorum/Version.pm');

requires 'Template::Plugin::Math'; # Template 2.19 don't contain this one.
requires 'Template';
requires 'DBIx::Class';
requires 'Catalyst' => '5.64';
requires 'Digest';
requires 'DateTime';
requires 'File::Path';
requires 'File::Copy';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Sub::Install'; # thanks for sai
requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Config::YAML::XS';
requires 'Cache::FileCache';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::PageCache';
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
requires 'I18N::LangTags'; # for I18N::LangTags::Detect
requires 'Catalyst::Plugin::I18N';
requires 'Template::Plugin::FillInForm';
requires 'Template::Plugin::Date';
requires 'File::Remove';
requires 'HTML::Email::Obfuscate';
requires 'Locale::Country::Multilingual' => '0.03'; # for tw lang
#requires 'File::Slurp';
requires 'Net::IP::Match::Regexp';
requires 'Net::CIDR::Lite';

# search
requires 'Sphinx::Search';

# cron
requires 'TheSchwartz';
requires 'Schedule::Cron';
requires 'Proc::PID::File';
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

# mail
requires 'MIME::Entity';
requires 'Email::Send';
recommends 'Email::Send::SMTP::TLS';

# formatter
requires 'HTML::BBCode' => '2.00';
requires 'Text::Textile';
requires 'URI::Find::UTF8';
requires 'Text::GooglewikiFormat' => '0.04';

# db debug
requires 'Catalyst::Model::DBIC::Schema::QueryLog';

catalyst;

#install_script glob('script/*.pl');
auto_install;
WriteAll;
