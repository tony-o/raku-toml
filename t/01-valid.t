#!/usr/bin/env raku

use TOML;
use JSON::Fast;
use Test;

#gather toml files
my @files = 't/valid'.IO.dir.grep: { $_.extension eq 'toml' };
plan +@files;
my $count = 0;
my ($pass, $expect, $toml);

for @files.sort -> $f {
  $toml   = from-toml($f.slurp, :test);
  $expect = from-json((S/toml$/json/ given $f.absolute).IO.slurp);
  $pass   = ok(to-json($toml, :pretty, :sorted-keys) eq to-json($expect, :pretty, :sorted-keys), (S/toml$/json/ given $f.relative));
  if !$pass {
    say to-json($toml, :pretty, :sorted-keys);
    say to-json($expect, :pretty, :sorted-keys);
    die;
  }
}
