package Foorum::Model::FilterWord;

use strict;
use warnings;
use base 'Catalyst::Model';
use Data::Dumper;

sub get_data {
    my ( $self, $c, $type ) = @_;

    return unless ($type);
    my $cache_key   = "filter_word|type=$type";
    my $cache_value = $c->cache->get($cache_key);
    return wantarray ? @{ $cache_value->{value} } : $cache_value->{value}
        if ($cache_value);

    my @value;
    my @rs = $c->model('DBIC::FilterWord')->search( { type => $type } )->all;
    push @value, $_->word foreach (@rs);
    $cache_value = { value => \@value };
    $c->cache->set( $cache_key, $cache_value, 3600 );    # 1 hour

    return wantarray ? @value : \@value;
}

# for offensive word, we just convert part of the word into '*' by default
# for bad word, we always print_error to stop submit by default

sub has_bad_word {
    my ( $self, $c, $text, $attr ) = @_;

    my $RaiseError = ( exists $attr->{RaiseError} ) ? $attr->{RaiseError} : 1;

    my @bad_words = $self->get_data( $c, 'bad_word' );
    foreach my $word (@bad_words) {
        if ( $text =~ /$word/ ) {
            if ($RaiseError) {
                $c->detach( '/print_error',
                    [qq~Sorry, your input has a bad word "$word".~] );
            } else {
                return 1;
            }
            last;    # out foreach
        }
    }
    return 0;
}

sub convert_offensive_word {
    my ( $self, $c, $text ) = @_;

    my @offensive_words = $self->get_data( $c, 'offensive_word' );
    foreach my $word (@offensive_words) {
        if ( $text =~ /$word/ ) {
            my $asterisk_word   = $word;
            my $converted_chars = 0;
            foreach my $offset ( 2 .. length($word) ) {
                next
                    if ( int( rand(10) ) % 2 == 1 )
                    ;    # randomly skip some chars
                substr( $asterisk_word, $offset - 1, 1 ) = '*';
                $converted_chars++;
                last if ( $converted_chars == 2 );    # that's enough
            }
            substr( $asterisk_word, 1, 1 ) = '*'
                unless ( $asterisk_word =~ /\*/is );
            $text =~ s/\b$word\b/$asterisk_word/isg;
        }
    }
    return $text;
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
