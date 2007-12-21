#!/usr/bin/perl -w

use strict;
use Encode::HanConvert;

use FindBin qw/$Bin/;
use Cwd qw/abs_path/;

my $home = abs_path("$Bin/../../"); # Foorum home dir

local $/ = undef;

# for lib/Foorum/I18N/cn.po
open(FH, "<$home/lib/Foorum/I18N/cn.po");
flock(FH, 1);
binmode(FH, ':encoding(simp-trad)');
my $simp = <FH>;
close(FH);

my $trad = simp_to_trad($simp);

open(FH, ">$home/lib/Foorum/I18N/tw.po");
flock(FH, 2);
binmode(FH, ':utf8');
print FH $trad;
close(FH);

print "lib/Foorum/I18N/tw.po OK\n";

# for root/js/jquery/validate/messages_cn.js
open(FH, "<$home/root/static/js/jquery/validate/messages_cn.js");
flock(FH, 1);
binmode(FH, ':encoding(simp-trad)');
$simp = <FH>;
close(FH);

$trad = simp_to_trad($simp);

open(FH, ">$home/root/static/js/jquery/validate/messages_tw.js");
flock(FH, 2);
binmode(FH, ':utf8');
print FH $trad;
close(FH);

print "root/static/js/jquery/validate/messages_cn.js OK\n";

# for root/js/site/formatter/ubbhelp-cn.js
open(FH, "<$home/root/static/js/site/formatter/ubbhelp-cn.js");
flock(FH, 1);
binmode(FH, ':encoding(simp-trad)');
$simp = <FH>;
close(FH);

$trad = simp_to_trad($simp);

open(FH, ">$home/root/static/js/site/formatter/ubbhelp-tw.js");
flock(FH, 2);
binmode(FH, ':utf8');
print FH $trad;
close(FH);

print "root/js/static/site/formatter/ubbhelp-cn.js OK\n";

1;