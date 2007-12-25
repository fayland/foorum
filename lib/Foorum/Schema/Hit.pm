package Foorum::Schema::Hit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hit");
__PACKAGE__->add_columns(
    "hit_id",
    {   data_type     => "INT",
        default_value => undef,
        is_nullable   => 0,
        size          => 11
    },
    "object_type",
    {   data_type     => "VARCHAR",
        default_value => undef,
        is_nullable   => 0,
        size          => 12,
    },
    "object_id",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_new",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_today",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_yesterday",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_weekly",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_monthly",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "hit_all",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
    "last_update_time",
    { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("hit_id");

# Created by DBIx::Class::Schema::Loader v0.04004 @ 2007-12-23 13:01:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yJMY6otOWdDk1XJAuOQTBA

# You can replace this text with custom content, and it will be preserved on regeneration
1;
