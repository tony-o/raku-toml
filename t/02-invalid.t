#!/usr/bin/env raku

use TOML;
use Test;
use lib 't/lib';
use TOML::Test;

my @files = |@*ARGS.map(*.IO) // 't/invalid'.IO.dir.grep: { $_.extension eq 'toml' };
plan +@files;
my $count = 0;
my ($pass, $expect, $toml);

for @files.sort -> $f {
  $toml   = from-toml($f.slurp);
  $pass   = ok(!$toml, $f.relative);
  if !$pass {
    say '===TOML';
    say $f.slurp;
    say '===EXPECT';
    dd $expect;
    say '===GOT';
    dd $toml;
    die;
    die;
  }
}
