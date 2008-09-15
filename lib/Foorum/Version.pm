package Foorum;

our $VERSION = '0.2.3';

1;
__END__

=head1 NAME

Foorum::Version - The Foorum project-wide version number

=head1 SYNOPSIS

    package Foorum::Whatever;

    # Must be on one line so MakeMaker can parse it.
    use Foorum::Version;  our $VERSION = $Foorum::VERSION;

=head1 DESCRIPTION

Because of the problems coordinationg revision numbers in a distributed
version control system and across a directory full of Perl modules, this
module provides a central location for the project's release number.

=head1 IDEA FROM

This idea was taken from L<SVK> and inspired by L<Parley> directly

=cut
