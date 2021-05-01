#!/usr/bin/env raku

use TOML;
use Test;
use lib 't/lib';
use TOML::Test;
sub from-json($text) { ::("Rakudo::Internals::JSON").from-json($text) }

#gather toml files
my @files = |@*ARGS.map(*.IO) // 't/valid'.IO.dir.grep: { $_.extension eq 'toml' };
plan +@files;
my ($pass, $expect, $toml);

for @files.sort -> $f {
  $toml   = from-toml($f.slurp);
  $expect = from-json((S/toml$/json/ given $f.absolute).IO.slurp);
  $pass   = ok(cmp($expect, $toml), (S/toml$/json/ given $f.relative));
  unless $pass {
    say '===TOML';
    say $f.slurp;
    say '===EXPECT';
    say to-json $expect, :sorted-keys;
    say '===GOT';
    say to-json $toml, :sorted-keys;
    die;
  }
}
