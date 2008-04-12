package Foorum::Schema::Upload;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ResultSetManager Core/);
__PACKAGE__->table("upload");
__PACKAGE__->add_columns(
  "upload_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "forum_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 36,
  },
  "filesize",
  { data_type => "DOUBLE", default_value => undef, is_nullable => 1, size => 64 },
  "filetype",
  { data_type => "VARCHAR", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("upload_id");

use File::Remove qw(remove);
use File::Path;
use File::Copy ();
use Foorum::Utils qw/generate_random_word/;
use Scalar::Util ();

sub get : ResultSet {
    my ( $self, $upload_id ) = @_;

    return unless ( $upload_id =~ /^\d+$/ );

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key = "upload|upload_id=$upload_id";
    my $cache_val = $cache->get($cache_key);
    return $cache_val if ($cache_val);

    my $upload = $self->find( { upload_id => $upload_id } );
    return unless ($upload);

    $cache_val = $upload->{_column_data};
    $cache->set( $cache_key, $cache_val, 7200 );    # two hours

    return $cache_val;
}

sub remove_for_forum : ResultSet {
    my ( $self, $forum_id ) = @_;

    my $rs = $self->search( { forum_id => $forum_id },
        { columns => [ 'upload_id', 'filename' ], } );
    while ( my $u = $rs->next ) {
        $self->remove_by_upload($u);
    }
    return 1;
}

sub remove_for_user : ResultSet {
    my ( $self, $user_id ) = @_;

    my $rs = $self->search( { user_id => $user_id, },
        { columns => [ 'upload_id', 'filename' ], } );
    while ( my $u = $rs->next ) {
        $self->remove_by_upload($u);
    }
    return 1;
}

sub remove_file_by_upload_id : ResultSet {
    my ( $self, $upload_id ) = @_;

    my $upload = $self->get($upload_id);
    return unless ($upload);
    remove_by_upload( $self, $upload );
    return 1;
}

sub remove_by_upload : ResultSet {
    my ( $self, $upload ) = @_;

    if ( Scalar::Util::blessed($upload) ) {
        $upload = $upload->{_column_data};
    }

    my $schema    = $self->result_source->schema;
    my $cache     = $schema->cache();
    my $base_path = $schema->base_path();

    my $directory_1 = int( $upload->{upload_id} / 3200 / 3200 );
    my $directory_2 = int( $upload->{upload_id} / 3200 );
    my $file = "$base_path/root/upload/$directory_1/$directory_2/$upload->{filename}";
    remove($file);
    $self->search( { upload_id => $upload->{upload_id} } )->delete;

    $cache->remove( 'upload|upload_id=' . $upload->{upload_id} );
}

sub add_file : ResultSet {
    my ( $self, $upload, $info ) = @_;

    my $schema    = $self->result_source->schema;
    my $config    = $schema->config();
    my $base_path = $schema->base_path();

    my @valid_types = @{ $config->{upload}->{valid_types} };
    my $max_size    = $config->{upload}->{max_size};
    my ( $basename, $filesize ) = ( $upload->basename, $upload->size );
    $filesize /= 1024;    # I want K
    if ( $filesize > $max_size ) {
        return 'EXCEED_MAX_SIZE';
    }
    ($filesize) = ( $filesize =~ /^(\d+\.?\d{0,1})/ );    # float(6,1)

    my ( $filename_no_postfix, $filetype ) = ( $basename =~ /^(.*?)\.(\w+)$/ );
    $filetype = lc($filetype);
    unless ( grep { $filetype eq $_ } @valid_types ) {
        return 'UNSUPPORTED_FILETYPE';
    }

    if ( length($filename_no_postfix) > 30 ) {
        $filename_no_postfix = substr( $filename_no_postfix, 0, 30 );    # varchar(36)
        $basename = $filename_no_postfix . ".$filetype";
    }
    my $upload_rs = $self->create(
        {   user_id  => $info->{user_id},
            forum_id => $info->{forum_id} || 0,
            filename => $basename,
            filesize => $filesize,
            filetype => $filetype,
        }
    );

    my $upload_id = $upload_rs->upload_id;

    my $directory_1 = int( $upload_id / 3200 / 3200 );
    my $directory_2 = int( $upload_id / 3200 );
    my $upload_dir  = "$base_path/root/upload/$directory_1/$directory_2";

    unless ( -e $upload_dir ) {
        my @created
            = mkpath( [$upload_dir], 0, 0777 );    ## no critic (ProhibitLeadingZeros)
               # copy index.html to protect dir from Options Indexes
        my $indexfile = "$base_path/root/upload/index.html";
        foreach my $dir (@created) {
            File::Copy::copy( $indexfile, $dir );
        }
    }

    my $target = "$base_path/root/upload/$directory_1/$directory_2/$basename";

    # rename if exist
    if ( -e $target ) {
        my $random_filename;
        while ( -e $target ) {
            $random_filename = generate_random_word(15) . ".$filetype";
            $target = "$base_path/root/upload/$directory_1/$directory_2/$random_filename";
        }
        $upload_rs->update( { filename => $random_filename } );
    }

    unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
        return 'SYSTEM_ERROR';
    }

    return $upload_id;
}

sub change_for_forum : ResultSet {
    my ( $self, $info ) = @_;

    my $from_id = $info->{form_id} or return 0;
    my $to_id   = $info->{to_id}   or return 0;

    $self->search( { forum_id => $from_id, } )->update( { forum_id => $to_id, } );
}

1;
