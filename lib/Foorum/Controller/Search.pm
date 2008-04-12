package Foorum::Controller::Search;

use strict;
use warnings;
use base 'Catalyst::Controller';

=pod

use Foorum::Utils qw/get_page_from_url/;
use Foorum::Logger qw/error_log/;
use Data::Page;
use Sphinx::Search;

sub auto : Private {
    my ( $self, $c ) = @_;

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
    my $per_page = 20;
    $sphinx->SetSortMode(SPH_SORT_ATTR_DESC, 'date_added');
    $sphinx->SetMatchMode(SPH_MATCH_ANY);
    $sphinx->SetLimits( ($page - 1) * $per_page, $per_page, 20 * $per_page); # MAX is 20 pages
    $sphinx->SetFilter( 'forum_id', [$forum_id] );
    
    $title = $sphinx->EscapeString($title);
    my $ret = $sphinx->Query("\@title $title");
    
    # deal with error of Sphinx
    unless ($ret) {
        my $err = $sphinx->GetLastError;
        error_log( $c->model('DBIC'), 'fatal', $err );
        
        $c->detach('/print_error', [ 'Search is not going well, we will fix it ASAP.' ] );
    }
    
    use Data::Dumper;
    return $c->res->body(Dumper(\$ret));
    
    my @matches = @{$ret->{matches}};
    my @topic_ids;
    foreach my $r (@matches) {
        # $r is something like
#        {
#         'author_id' => 1,
#         'forum_id' => 1,
#         'date_added' => 1200814358,
#         'weight' => 1,
#         'object_id' => 25,
#         'doc' => 108
#        },
        # while the doc is $comment_id and object_id is $topic_id
        push @topic_ids, $r->{object_id};
    }
    
    # pager
    my $total = $ret->{total_found};
    my $pager = Data::Page->new();
    $pager->total_entries($total);
    $pager->entries_per_page($per_page);
    $pager->current_page($page);
    $c->stash( {
        pager => $pager
    } );
    
    
}

=cut

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
