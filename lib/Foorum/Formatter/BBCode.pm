package Foorum::Formatter::BBCode;

use strict;
use warnings;
use base 'HTML::BBCode::Strict';
use Class::C3;              # for next::method();

#our @bbcode_tags
#    = qw(email flash music);

sub new {
    my ( $class, $conf, $tags ) = @_;

    # our tags
    $tags->{size} = {
        has_closing_tag        => 1,
        arg_required           => 1,
        tags_can_be_inside     => [ qw/ b u i s color / ],
        pattern      => sub {
            qq#<span style="font-size: $_[1]pt;">$_[0]</span>#;
        }
    };
    $tags->{font} = {
        has_closing_tag        => 1,
        arg_required           => 1,
        tags_can_be_inside     => [ qw/ b u i s color / ],
        pattern      => sub {
            qq#<span style="font-family: $_[1];">$_[0]</span>#;
        }
    };

    my $self = $class->next::method($conf, $tags);
    
    return $self;
}

1;
