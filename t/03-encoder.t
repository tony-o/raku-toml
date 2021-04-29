#!/usr/bin/env raku

use TOML;
use Test;
use lib 't/lib';
use TOML::Test;

my @files = |@*ARGS.map(*.IO) // 't/valid'.IO.dir.grep: { $_.extension eq 'toml' };
plan +@files;

my ($pass, $expect, $toml, $out);

for @files.sort -> $f {
  $expect = from-toml($f.slurp);
  $out    = try to-toml($expect);
  $toml   = try from-toml($out);
  $pass   = try { ok(cmp($toml, $expect), $f) } // False;
  unless $pass {
    say '===TOML';
    say $f.slurp;
    say '===EXPECT';
    dd $expect;
    say '===GOT';
    dd $toml;
    die;
  }
}
