package Foorum::Model::Upload;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;
use File::Remove qw(remove);
use File::Path;
use Foorum::Utils qw/generate_random_word/;
use Scalar::Util ();

sub get {
    my ( $self, $c, $upload_id ) = @_;

    return unless ( $upload_id =~ /^\d+$/ );
    my $cache_key = "upload|upload_id=$upload_id";
    my $cache_val = $c->cache->get($cache_key);
    return $cache_val if ($cache_val);

    my $upload = $c->model('DBIC')->resultset('Upload')
        ->find( { upload_id => $upload_id } );
    return unless ($upload);

    $cache_val = $upload->{_column_data};
    $c->cache->set( $cache_key, $cache_val, 7200 );    # two hours

    return $cache_val;
}

sub remove_for_forum {
    my ( $self, $c, $forum_id ) = @_;

    my $rs = $c->model('DBIC::Upload')->search( { forum_id => $forum_id, },
        { columns => [ 'upload_id', 'filename' ], } );
    while ( my $u = $rs->next ) {
        remove_by_upload( $self, $c, $u );
    }
    return 1;
}

sub remove_for_user {
    my ( $self, $c, $user_id ) = @_;

    my $rs = $c->model('DBIC::Upload')->search( { user_id => $user_id, },
        { columns => [ 'upload_id', 'filename' ], } );
    while ( my $u = $rs->next ) {
        remove_by_upload( $self, $c, $u );
    }
    return 1;
}

sub remove_file_by_upload_id {
    my ( $self, $c, $upload_id ) = @_;

    my $upload = get( $self, $c, $upload_id );
    return unless ($upload);
    remove_by_upload( $self, $c, $upload );
    return 1;
}

sub remove_by_upload {
    my ( $self, $c, $upload ) = @_;

    if ( Scalar::Util::blessed($upload) ) {
        $upload = $upload->{_column_data};
    }

    my $directory_1 = int( $upload->{upload_id} / 3200 / 3200 );
    my $directory_2 = int( $upload->{upload_id} / 3200 );
    my $file = $c->path_to( 'root', 'upload', $directory_1, $directory_2,
        $upload->{filename} )->stringify;
    remove($file);
    $c->model('DBIC::Upload')->search( { upload_id => $upload->{upload_id} } )
        ->delete;

    $c->cache->delete( 'upload|upload_id=' . $upload->{upload_id} );
}

sub add_file {
    my ( $self, $c, $upload, $info ) = @_;

    my @valid_types = @{ $c->config->{upload}->{valid_types} };
    my $max_size    = $c->config->{upload}->{max_size};
    my ( $basename, $filesize ) = ( $upload->basename, $upload->size );
    $filesize /= 1024;    # I want K
    if ( $filesize > $max_size ) {
        $c->log->debug('EXCEED_MAX_SIZE');
        $c->stash->{upload_error} = 'EXCEED_MAX_SIZE';
        return 0;
    }
    ($filesize) = ( $filesize =~ /^(\d+\.?\d{0,1})/ );    # float(6,1)

    my ( $filename_no_postfix, $filetype )
        = ( $basename =~ /^(.*?)\.(\w+)$/ );
    $filetype = lc($filetype);
    unless ( grep { $filetype eq $_ } @valid_types ) {
        $c->log->debug("UNSUPPORTED_FILETYPE, $filetype");
        $c->stash->{upload_error} = 'UNSUPPORTED_FILETYPE';
        return 0;
    }

    if ( length($filename_no_postfix) > 30 ) {
        $filename_no_postfix
            = substr( $filename_no_postfix, 0, 30 );    # varchar(36)
        $basename = $filename_no_postfix . ".$filetype";
    }
    my $upload_rs = $c->model('DBIC::Upload')->create(
        {   user_id  => $c->user->user_id,
            forum_id => $info->{forum_id} || 0,
            filename => $basename,
            filesize => $filesize,
            filetype => $filetype,
        }
    );

    my $upload_id = $upload_rs->upload_id;

    my $directory_1 = int( $upload_id / 3200 / 3200 );
    my $directory_2 = int( $upload_id / 3200 );
    my $upload_dir
        = $c->path_to( 'root', 'upload', $directory_1, $directory_2 )
        ->stringify;
    mkpath( [$upload_dir], 0, 0777 );    # mkdir -p

    my $target = $c->path_to( 'root', 'upload', $directory_1, $directory_2,
        $basename )->stringify;

    # rename if exist
    if ( -e $target ) {
        my $random_filename;
        while ( -e $target ) {
            $random_filename = generate_random_word(15) . ".$filetype";
            $target
                = $c->path_to( 'root', 'upload', $directory_1, $directory_2,
                $random_filename )->stringify;
        }
        $upload_rs->update( { filename => $random_filename } );
    }

    unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
        $c->stash->{upload_error} = 'SYSTEM_ERROR';
        return 0;
    }

    return $upload_id;
}

sub change_for_forum {
    my ( $self, $c, $info ) = @_;

    my $from_id = $info->{form_id} or return 0;
    my $to_id   = $info->{to_id}   or return 0;

    $c->model('DBIC::Upload')->search( { forum_id => $from_id, } )
        ->update( { forum_id => $to_id, } );
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
