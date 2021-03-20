unit module TOML;

use TOML::Grammar;
use TOML::Actions;

sub from-toml(Str $d, Bool :$test = False) is export {
  try {
    TOML::Grammar.parse($d, :actions(TOML::Actions)).made
  } // Nil;
}
