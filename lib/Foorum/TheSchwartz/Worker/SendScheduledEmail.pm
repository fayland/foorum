package Foorum::TheSchwartz::Worker::SendScheduledEmail;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema config/;
use Foorum::Log qw/error_log/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $schema = schema();

    my $rs = $schema->resultset('ScheduledEmail')->search( { processed => 'N' } );
    
    my $handled = 0;
    while (my $rec = $rs->next) {
        
        send_email( $rec->from_email, $rec->to_email, $rec->subject, $rec->plain_body, $rec->html_body );
        
        # update processed
        $rec->update( { processed => 'Y' } );
        $handled++;
    }
    
    if ($handled) {
        error_log($schema, 'info', "$0 - sent: $handled");
    }

    $job->completed();
}

use MIME::Entity;
use Email::Send;
use YAML qw/LoadFile/;
use File::Spec;

my (undef, $path) = File::Spec->splitpath(__FILE__);
my $config = LoadFile("$path/../../../../conf/mail.yml");

my $mailer = Email::Send->new( $config );

sub send_email {
    my ($from, $to, $subject, $plain_body, $html_body) = @_;
    
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
}

1;