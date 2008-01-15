package Foorum::TheSchwartz::Worker::Topic_ViewAsPDF;

use strict;
use warnings;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema config base_path error_log tt2 cache/;
use Foorum::Formatter qw/filter_format/;
use Foorum::Adaptor::User;
use PDF::FromHTML;

my $user_model = new Foorum::Adaptor::User();

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my ($args) = $job->arg;
    my ( $forum_id, $topic_id, $random_word ) = @$args;

    my $schema    = schema();
    my $config    = config();
    my $cache     = cache();
    my $base_path = base_path();
    my $tt2       = tt2();
    
    my $file ="$base_path/root/upload/pdf/$forum_id-$topic_id-$random_word.pdf";
    my $var; # tt2 vars.

    # get comments
    my $cache_key   = "comment|object_type=topic|object_id=$topic_id";
    my $cache_value = $cache->get($cache_key);
    my @comments;
    if ($cache_value) {
        @comments = @{ $cache_value->{comments} };
    } else {
        my $it = $schema->resultset('Comment')->search(
            {   object_type => 'topic',
                object_id   => $topic_id,
            },
            {   order_by => 'post_on',
            }
        );

        while ( my $rec = $it->next ) {
            $rec = $rec->{_column_data};    # for cache using

            # filter format by Foorum::Filter
#            $rec->{title}
#                = $c->model('FilterWord')->convert_offensive_word( $c, $rec->{title} );
#            $rec->{text}
#                = $c->model('FilterWord')->convert_offensive_word( $c, $rec->{text} );
            $rec->{text} = filter_format( $rec->{text}, { format => $rec->{formatter} } );

            push @comments, $rec;
        }
    }
    foreach (@comments) {
        $_->{author} = $user_model->get( { user_id => $_->{author_id} } );
    }
    $var->{comments} = \@comments;
    
    # get topic
    my $topic = $schema->resultset('Topic')->find( { topic_id => $topic_id } );
    $var->{topic} = $topic;

    my $pdf_body;
    $tt2->process( 'topic/topic.pdf.html', $var, \$pdf_body );
        
    my $pdf = PDF::FromHTML->new( encoding => 'utf-8' );
    $pdf->load_file(\$pdf_body);
    $pdf->convert();
    $pdf->write_file($file);

    $job->completed();
}

1;
