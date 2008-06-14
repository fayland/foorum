package Foorum::Controller::Search;

use strict;
use warnings;
use Foorum::Version;  our $VERSION = $Foorum::VERSION;
use base 'Catalyst::Controller';
use Foorum::Utils qw/get_page_from_url/;
use Foorum::Logger qw/error_log/;
use Data::Page;
use Sphinx::Search;

sub begin : Private {
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
    # date value would be 2, 7, 30, 999
    $date = 0 if ($date != 2 and $date != 7 and $date != 30 and $date != 999);
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
        # date value would be 2, 7, 30, 999
        my $now = time();
        if ($date == 999) { # more than 30 days
            $sphinx->SetFilterRange('last_update_date', $now - 30 * 86400, $now, 1);
        } else {
        	  $sphinx->SetFilterRange('last_update_date', $now - $date * 86400, $now);
        }
    }
    
    my $page = get_page_from_url($c->req->path);
    my $per_page = 20;
    $sphinx->SetSortMode(SPH_SORT_ATTR_DESC, 'last_update_date');
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

    my @matches = @{$ret->{matches}};
    my @topics;
    foreach my $r (@matches) {
        my $topic_id = $r->{doc};
        my $topic = $c->model('DBIC')->resultset('Topic')->get($topic_id, { with_author => 1 } );
        push @topics, $topic;
    }
    $c->stash->{topics} = \@topics;
    
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

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
