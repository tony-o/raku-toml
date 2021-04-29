#!/usr/bin/env raku

use lib 'lib';
use TOML;

my $toml = q|
y = 5
|;
#x = [ [ {a = 1}, { b= 2} ]]
#|;
#nested_array_table = [
#    [ {value = 1}, {value = 0} ],
#    [ {value = 0}, {value = 1, comment = "bottom right diagonal element"} ] ]
#|;

#  [[a]]
#  x=1
#  y=2
#  [[a]]
#  x=-1
#  y=-2
#  pt={x=-1,y=-2}
#|
#;

my $dd = from-toml($toml);
dd $toml;
dd $dd;
