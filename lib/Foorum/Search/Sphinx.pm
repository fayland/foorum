package Foorum::Search::Sphinx;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;

use Sphinx::Search;
use Foorum::SUtils qw/schema/;

sub new {
    my $class = shift;
    my $self  = {@_};

    # check if Sphinx is available
    # YYY? TODO, make localhost/3312 configurable
    my $sphinx = Sphinx::Search->new();
    $sphinx->SetServer( 'localhost', 3312 );

    $self->{sphinx} = $sphinx;
    $self->{schema} = schema();

    return bless $self => $class;
}

sub can_search { return shift->{sphinx}->_Connect(); }

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

    my $sphinx = $self->{sphinx};
    my $schema = $self->{schema};
    $sphinx->ResetFilters();

    $sphinx->SetFilter( 'forum_id',  [$forum_id] )  if ($forum_id);
    $sphinx->SetFilter( 'author_id', [$author_id] ) if ($author_id);

    if ($date) {

        # date value would be 2, 7, 30, 999
        my $now = time();
        if ( $date == 999 ) {    # more than 30 days
            $sphinx->SetFilterRange( 'last_update_date', $now - 30 * 86400, $now, 1 );
        } else {
            $sphinx->SetFilterRange( 'last_update_date', $now - $date * 86400, $now );
        }
    }

    $sphinx->SetSortMode( SPH_SORT_ATTR_DESC, 'last_update_date' );
    $sphinx->SetMatchMode(SPH_MATCH_ANY);
    $sphinx->SetLimits( ( $page - 1 ) * $per_page, $per_page, 20 * $per_page )
        ;                        # MAX is 20 pages

    my $query;
    if ($title) {
        $title = $sphinx->EscapeString($title);
        $query = "\@title $title";
    }
    my $ret = $sphinx->Query($query);

    # deal with error of Sphinx
    unless ($ret) {
        my $err = $sphinx->GetLastError;
        return { error => $err };
    }

    my @matches = @{ $ret->{matches} };
    my @topic_ids;
    foreach my $r (@matches) {
        my $topic_id = $r->{doc};
        push @topic_ids, $topic_id;
    }

    return {
        matches => \@topic_ids,
        total   => $ret->{total_found},
    };
}

1;
__END__

=pod

=head1 NAME

Foorum::Search::Sphinx - search Foorum by Sphinx

=head1 SYNOPSIS

  use Foorum::Search::Sphinx;
  # TODO

=head1 DESCRIPTION

This module implements Sphinx for Foorum Search.

=head1 SEE ALSO

L<Foorum::Search>, L<Foorum::Search::Database>, L<Sphinx::Search>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
