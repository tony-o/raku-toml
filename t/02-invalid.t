#!/usr/bin/env raku

use TOML;
use JSON::Fast;
use Test;

#gather toml files
my @files = 't/invalid'.IO.dir.grep: { $_.extension eq 'toml' };
plan +@files;
my $count = 0;
my ($pass, $expect, $toml);

for @files.sort -> $f {
  $toml   = from-toml($f.slurp, :test);
  $pass   = ok(!$toml, $f.relative);
  if !$pass {
    say try { to-json($toml, :pretty, :sorted-keys) } or 'xxx';
    die;
  }
}
