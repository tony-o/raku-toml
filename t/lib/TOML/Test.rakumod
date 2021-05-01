unit module TOML::Test;

sub cmp($a, $b) is export {
  if $a ~~ Array {
    return False if $a.elems !~~ $b.elems;
    for 0..^+$a -> $i {
      return False unless cmp($a[$i], $b[$i]);
    }
    return True;
  } elsif $a ~~ Bool {
    return $a == $b;
  } elsif $a ~~ Str {
    return $a eq $b;
  } elsif $a ~~ Num|Int|Rat {
    warn "$a vs $b" if $a != $b; 
    return $a == $b;
  } elsif $a ~~ DateTime {
    return $a.Instant == $b.Instant;
  } elsif $a ~~ Hash {
    for $a.keys -> $k {
      return False unless cmp($a{$k}, $b{$k});
    }
    return True;
  }
  die $a.WHAT.^name ~ ' type unknown';
}
