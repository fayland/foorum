package Foorum::Search::Database;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;

use Foorum::SUtils qw/schema/;

sub new {
    my $class = shift;
    my $self  = {@_};

    $self->{schema} = schema();

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

sub forum {
    my ( $self, $params ) = @_;

    my $forum_id  = $params->{'forum_id'};
    my $title     = $params->{'title'};
    my $author_id = $params->{'author_id'};
    my $date      = $params->{'date'};
    my $page      = $params->{'page'} || 1;
    my $per_page  = $params->{per_page} || 20;

    my $schema = $self->{schema};

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
        $where->{title} = { 'LIKE', '%' . $title . '%' };
    }

    $attr->{rows}     = $per_page;
    $attr->{page}     = $page;
    $attr->{columns}  = ['topic_id'];
    $attr->{order_by} = \'last_update_date DESC';    #'

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

1;
__END__

=pod

=head1 NAME

Foorum::Search::Database - search Foorum by DBI

=head1 SYNOPSIS

  use Foorum::Search::Database;
  # TODO

=head1 DESCRIPTION

This module implements DBI for Foorum Search.

=head1 SEE ALSO

L<Foorum::Search>, L<Foorum::Search::Sphinx>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
