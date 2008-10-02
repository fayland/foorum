package Foorum::ResultSet::ForumSettings;

use strict;
use warnings;
use Foorum::Version; our $VERSION = $Foorum::VERSION;
use base 'DBIx::Class::ResultSet';

sub get_forum_settings {
    my ( $self, $forum, $opts ) = @_;

    my $schema   = $self->result_source->schema;
    my $forum_id = $forum->{forum_id};

    my $settings;

    my @extra_cols;
    if ( not exists $opts->{all} ) {
        my @all_types = qw/can_post_threads can_post_replies can_post_polls/;
        $settings->{$_} = 'Y' foreach (@all_types);
        @extra_cols = ( type => { 'IN', \@all_types } );
    }

    my $settings_rs = $self->search(
        {   forum_id => $forum_id,
            @extra_cols,
        }
    );
    while ( my $r = $settings_rs->next ) {
        $settings->{ $r->type } = $r->value;
    }

    return $settings;
}

1;
__END__

=pod

=head1 NAME

Foorum::ResultSet::ForumSettings - ForumSettings object

=head1 FUNCTION

=over 4

=item get_forum_settings($forum_obj, $opts)

  $schema->resultset('ForumSettings')->get_forum_settings( $forum );
  $c->model('DBIC::ForumSettings')->get_forum_settings( $forum, { all => 1 } );

It gets the data from forum_settings table. by default, we only get the settings of my @all_types = qw/can_post_threads can_post_replies can_post_polls/;

while pass $opts as { all => 1 } can get all forum settings including create_time and others

return $HASHREF

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
