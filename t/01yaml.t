#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Test::YAML::Valid;";    ## no critic (ProhibitStringyEval)

    $@ and plan skip_all => "Test::YAML::Valid is required for this test";

    plan tests => 14;
}

use Foorum::XUtils qw/base_path/;

my $base_path = base_path();

# XXX? since make test copy files to blib
$base_path =~ s/\/blib$//isg;

ok( -e "$base_path/foorum.yml", 'foorum.yml exists' );
yaml_file_ok( "$base_path/foorum.yml", 'foorum.yml validates' );

ok( -e "$base_path/conf/cron.yml", 'conf/cron.yml exists' );
yaml_file_ok( "$base_path/conf/cron.yml", 'conf/cron.yml validates' );

ok( -e "$base_path/conf/examples/scraper.yml", 'conf/examples/scraper.yml exists' );
yaml_file_ok( "$base_path/conf/examples/scraper.yml",
    'conf/examples/scraper.yml validates' );

ok( -e "$base_path/conf/examples/mail/Gmail.yml", 'conf/examples/mail/Gmail.yml exists' );
yaml_file_ok( "$base_path/conf/examples/mail/Gmail.yml",
    'conf/examples/mail/Gmail.yml validates' );

ok( -e "$base_path/conf/examples/mail/sendmail.yml",
    'conf/examples/mail/sendmail.yml exists'
);
yaml_file_ok(
    "$base_path/conf/examples/mail/sendmail.yml",
    'conf/examples/mail/sendmail.yml validates'
);

ok( -e "$base_path/conf/examples/theschwartz.yml",
    'conf/examples/theschwartz.yml exists'
);
yaml_file_ok(
    "$base_path/conf/examples/theschwartz.yml",
    'conf/examples/theschwartz.yml validates'
);

ok( -e "$base_path/conf/examples/mail/SMTP.yml", 'conf/examples/mail/SMTP.yml exists' );
yaml_file_ok( "$base_path/conf/examples/mail/SMTP.yml",
    'conf/examples/mail/SMTP.yml validates' );

1;
