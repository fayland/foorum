package Foorum::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Sphinx::Search;

sub auto : Private {
    my ( $self, $c ) = @_;

=pod

    # make sure Sphinx is on
    eval {
        require Sphinx::Search;
        Sphinx::Search->import();
    };
    if ($@) {
        $c->forward('/print_error', [ 'Function Disabled' ] );
        return 0;
    }

=cut

    my $sphinx = Sphinx::Search->new();
    $sphinx->SetServer( 'localhost', 3312 );
    $c->stash->{sphinx} = $sphinx;
    
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'search/index.html';
}

# path $base/search/forum/($forum_id|$forum_code)
sub forum : Local {
    my ($self, $c) = @_;
    
    my ($forum_id) = ($c->req->path =~ /forum\/(\w+)(\/|$)/);
    my $forum = $c->controller('Get')->forum( $c, $forum_id );
    $forum_id = $forum->{forum_id};
    
    $c->stash->{template} = 'search/forum.html';
    
    my $title = $c->req->param('title');
    my $author = $c->req->param('author');
    my $date   = $c->req->param('date');
    return unless ($title or $author or $date);
    
    unless (length($title)) {
        return $c->stash->{error_title} = 'Title is required';
    }
    my $sphinx = $c->stash->{sphinx};
    if ($author) {
        my $user = $c->model('DBIC::User')->get( { username => $author } );
        return $c->stash->{error_author} = 'User not found' unless ($user);
        $sphinx->SetFilter('author_id', [ $user->{user_id} ]);
    }
    # XXX? TODO
    if ($date) {
        
        # $sphinx->SetFilterRange('birthday_days', $from_days, $to_days);
    }
    
    my $page = get_page_from_url($c->req->path);
    $sphinx->SetSortMode(SPH_SORT_ATTR_DESC, 'date_added');
    $sphinx->SetMatchMode(SPH_MATCH_ANY);
    #$sphinx->SetLimits( ($page - 1) * 20, 20, 400); # MAX is 400
    #$sphinx->SetFilter( 'forum_id', [$forum_id] );
    
    $title = $sphinx->EscapeString($title);
    my $ret = $sphinx->Query("\@title $title");
    
    use Data::Dumper;
    $c->res->body(Dumper(\$ret));
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
