package Foorum::Search::Database;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;

use Foorum::SUtils qw/schema/;

sub new {
    my $class = shift;
    my $self  = {@_};
    return bless $self => $class;
}

sub query {
    my ( $self, $type, $params ) = @_;

    if ( $self->can($type) ) {
        return $self->$type($params);
    } else {
        return;
    }
}

sub get_schema {
    my ($self) = @_;

    $self->{schema} = schema() unless ( $self->{schema} );
    return $self->{schema};
}

sub topic {
    my ( $self, $params ) = @_;

    my $forum_id  = $params->{'forum_id'};
    my $title     = $params->{'title'};
    my $author_id = $params->{'author_id'};
    my $date      = $params->{'date'};
    my $page      = $params->{'page'} || 1;
    my $per_page  = $params->{per_page} || 20;
    my $order_by  = $params->{order_by} || 'last_update_date';

    my $schema = $self->get_schema();

    my ( $where, $attr );

    $where->{forum_id}  = $forum_id  if ($forum_id);
    $where->{author_id} = $author_id if ($author_id);
    if ($date) {

        # date value would be 2, 7, 30, 999
        my $now = time();
        if ( $date == 999 ) {    # more than 30 days
            $where->{last_update_date} = { '<', $now - 30 * 86400 };
        } else {
            $where->{'-and'} = [
                last_update_date => { '>', $now - $date * 86400 },
                last_update_date => { '<', $now }
            ];
        }
    }
    if ($title) {

        #$title = $schema->storage->dbh->quote($title);
        $where->{title} = { 'LIKE', '%' . $title . '%' };
    }

    $attr->{rows}    = $per_page;
    $attr->{page}    = $page;
    $attr->{columns} = ['topic_id'];
    $attr->{order_by}
        = ( $order_by eq 'post_on' ) ? \'post_on DESC' : \'last_update_date DESC';

    my $rs = $schema->resultset('Topic')->search( $where, $attr );
    my @topic_ids;
    while ( my $r = $rs->next ) {
        push @topic_ids, $r->topic_id;
    }

    return {
        matches => \@topic_ids,
        pager   => $rs->pager,
    };
}

sub user {
    my ( $self, $params ) = @_;

    my $name     = $params->{name};
    my $gender   = $params->{gender};
    my $country  = $params->{country};
    my $page     = $params->{'page'} || 1;
    my $per_page = $params->{per_page} || 20;
    my $schema   = $self->{schema};

    my ( $where, $attr );
    $attr->{rows}    = $per_page;
    $attr->{page}    = $page;
    $attr->{columns} = ['user_id'];

    # prepare $where from $params
    if ($name) {
        $name = $schema->storage->dbh->quote($name);    # escape title
        $where->{nickname} = { 'LIKE', '%' . $name . '%' };
    }
    if ( $gender eq 'F' or $gender eq 'M' ) {
        $where->{gender} = $gender;
    }
    if ($country) {
        $where->{country} = $country;
    }

    my $rs = $schema->resultset('User')->search( $where, $attr );
    my @user_ids;
    while ( my $r = $rs->next ) {
        push @user_ids, $r->user_id;
    }

    return {
        matches => \@user_ids,
        pager   => $rs->pager,
    };
}

1;
__END__

=pod

=head1 NAME

Foorum::Search::Database - search Foorum by DBI

=head1 SYNOPSIS

  use Foorum::Search::Database;
  
  my $search = new Foorum::Search::Database;
  my $ret = $search->query('topic', { author_id => 1, title => 'test', page => 2, per_page => 20 } );
  # $ret would be something like:
  # { matches => \@topic_ids, pager => $instance_of_date_page }

=head1 DESCRIPTION

This module implements DBI for Foorum Search.  so generally you should check L<Foorum::Search> instead.

=head1 SEE ALSO

L<Foorum::Search>, L<Foorum::Search::Sphinx>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
