#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Data::Dumper;
my $config = LoadFile("$Bin/../../conf/mail.yml");

my $mailer = Email::Send->new( $config );

my $from = 'fayland@gmail.com';
my $to   = 'fayland.dreamhost@gmail.com';
my $subject = 'Test Foorum Function';
my $plain_body = Dumper(\$config);
my $html_body = Dumper(\$config);

    my $top = MIME::Entity->build(
        'X-Mailer' => undef,    # remove X-Mailer tag in header
        'Type'     => "multipart/alternative",
        'Reply-To' => $from,
        'From'     => $from,
        'To'       => $to,
        'Subject'  => $subject,
    );

    $top->attach(
		Encoding => '7bit',
        Type 	 => 'text/plain',
        Charset  => 'utf-8',
        Data	 => $plain_body,
	);
    
    if ($html_body) {
    	$top->attach(
    		Type 	 => 'text/html',
    		Encoding => '7bit',
    		Charset	 => 'utf-8',
    		Data => $html_body,
    	);
    }

	my $email = $top->stringify;
    $mailer->send($email);

1;