package Foorum::Schema::PollResult;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("poll_result");
__PACKAGE__->add_columns(
  "option_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "poll_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "poster_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "poster_ip",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-11-27 13:27:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3M66/Q9DKjNFZP5MBPp3rA


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->belongs_to(
    'poll' => 'Foorum::Schema::Poll',
    { 'foreign.poll_id' => 'self.poll_id' }
);
__PACKAGE__->belongs_to(
    'option' => 'Foorum::Schema::PollOption',
    { 'foreign.option_id' => 'self.option_id' }
);
1;
