package Foorum::TheSchwartz::Worker::ResizeProfilePhoto;

use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema/;
use File::Spec;
use Image::Magick;
use Cwd qw/abs_path/;
use File::Copy;

my (undef, $path) = File::Spec->splitpath(__FILE__);

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;
    
    my @args = $job->arg;
    
    my $schema = schema();

    # get upload from db
    my $upload_id = shift @args;
    if ($upload_id !~ /^\d+$/) {
        return $job->failed("Wrong upload_id: $upload_id");
    }
    my $upload = $schema->resultset('Upload')->find( { upload_id => $upload_id } );
    unless ($upload) {
        return $job->failed("No upload for $upload_id");
    }
    
    # get file dir
    my $directory_1 = int( $upload_id / 3200 / 3200 );
    my $directory_2 = int( $upload_id / 3200 );
    my $file = abs_path("$path/../../../../root/upload/$directory_1/$directory_2/" . $upload->filename);
    
    # resize photo
    my $p = new Image::Magick;
    $p->Read($file);
    $p->Scale(geometry=>'120x120');
    $p->Sharpen(geometry=>'0.0x1.0');
    $p->Set(quality=>'75');
    
    my ($width, $height, $size) = $p->Get('width', 'height', 'filesize');
    
    my $tmp_file = $file . '.tmp';
    $p->Write($tmp_file);
    
    move($tmp_file, $file);
    
    # update db
    $schema->resultset('UserProfilePhoto')->search( {
        type    => 'upload',
        value   => $upload_id,
    } )->update( {
        width  => int($width),
        height => int($height),
    } );
    $size /= 1024;    # I want K
    ($size) = ( $size =~ /^(\d+\.?\d{0,1})/ );    # float(6,1)
    $upload->update( { filesize => $size } );

    $job->completed();
}

sub max_retries { 3 };

1;