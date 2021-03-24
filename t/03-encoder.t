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
  $out    = to-toml($expect);
  $toml   = from-toml($out);
  $pass   = ok(cmp($toml, $expect), $f);
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
