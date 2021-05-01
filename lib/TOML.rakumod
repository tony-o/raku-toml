unit module TOML;

use TOML::NQP;
use TOML::Time;

sub from-toml(Str $d, Bool :$test = False) is export {
  try {
    #CATCH { default { .say; } }
    parse-toml($d);
  } // Nil;
}


sub sort-keys($obj) {
  $obj.keys.sort({
    $obj{$^a}.WHAT ~~ $obj{$^b}.WHAT ?? $^a cmp $^b !!
        ($obj{$^a}.WHAT ~~ Array ?? 1 !! $obj{$^a}.WHAT ~~ Hash ?? 0 !! -1)
    cmp ($obj{$^b}.WHAT ~~ Array ?? 1 !! $obj{$^b}.WHAT ~~ Hash ?? 0 !! -1)
  });
}

sub to-toml($obj) is export {
  die 'to-toml expects a hash, got: ' ~ $obj.WHAT.^name unless $obj ~~ Hash;
  x-to-toml($obj);
}

sub x-to-toml($obj, :@path = (), :$key = False, :$in-array is copy = False, Int :$array-space = 0) {
  if $obj ~~ Array {
    return "[]" if $obj.elems == 0;
    my $out = "["; #this can never be the opening object

    for 0..^$obj.elems -> $i {
      $out ~= x-to-toml($obj[$i]) ~ (",\n" ~ ' ' x $array-space if $i != $obj.elems - 1);
    }
    $out ~= "]"; #this can never be the opening object
    return $out;
  } elsif $obj ~~ Bool {
    return $obj ?? 'true' !! 'false';
  } elsif $obj ~~ Str {
    my @s = |$obj.split('', :skip-empty);
    my ($q, $o, $c) = ($key ?? '' !! '"');
    for 0..^@s -> $idx {
      $c = @s[$idx];
      $o = $c.ords.first;
      if $o >= 0x80 && $o <= 0xD7FF {
        $q = '"';
        @s[$idx] = sprintf('\u%04X', $o);
      } elsif $o >= 0xE000 && $o <= 0x10FFFF {
        $q = '"';
        @s[$idx] = sprintf('\U%08X', $o);
      } elsif (0x08, 0x0D, 0x09, 0x0C, 0x22, 0x5C).grep(* == $o) {
        @s[$idx] = do given $o {
          when 0x08 { "\\b" }
          when 0x09 { "\\t" }
          when 0x0C { "\\f" }
          when 0x0D { "\\r" }
          default   { sprintf("\\%s", $c); }
        };
      }
      if $o ~~ 0x0A|0x0D {
        $q = '"""';
      }
      if $q eq '' && ($o < 0x41 || $o > 0x5A)
                  && ($o < 0x61 || $o > 0x7A) {
        $q = '"';
      }
    }
    return sprintf('%s%s%s', $q, @s.join(''), $q);
  } elsif $obj ~~ Num|Rat {
    return $obj.Str;
  } elsif $obj ~~ Int {
    return $obj.Str;
  } elsif $obj ~~ DateTime {
    return $obj.Str;
  } elsif $obj.WHAT.^name eq 'Any' {
    return '{}'; #https://github.com/toml-lang/toml/issues/30#issuecomment-14004686
  }
  die "Unknown type: {$obj.WHAT.^name}" if $obj !~~ Hash;
  my @keys = sort-keys($obj);
  my $out = @path && !$in-array ?? sprintf("[%s]\n", @path.join('.')) !! '';
  my $ptr;
  $in-array ||= @path && !$in-array;
  for @keys -> $key {
    my $k = x-to-toml($key, :key);
    if $obj{$key} ~~ Hash {
      #make nice tables
      my @ks = sort-keys($obj{$key});
      if @ks.elems == 1 && $obj{$key}{@ks[0]} ~~ Hash {
        $out ~= x-to-toml($obj{$key}{@ks[0]}, path => (|@path, $k, x-to-toml(@ks[0])), :$in-array);
      } elsif @ks.elems == 0 {
        $out ~= sprintf("%s = \{\}\n", $in-array ?? $k !! (|@path, $k).join('.'));
      } else {
        for @ks -> $ks {
          if $obj{$key}{$ks} ~~ Hash {
            $out ~= x-to-toml($obj{$key}{$ks}, path => (|(!$in-array ?? @path !! ()), $k, x-to-toml($ks)), :$in-array);
          } elsif $obj{$key}{$ks} ~~ Array && $obj{$key}{$ks}.elems && $obj{$key}{$ks}[0] ~~ Hash {
            for |$obj{$key}{$ks} -> $ko {
              $out ~= sprintf("[[%s]]\n", (|@path, $k, x-to-toml($ks, :key)).join('.'));
              $out ~= x-to-toml($ko, path => (|(!$in-array ?? @path !! ()), $k, x-to-toml($ks, :key)), :in-array);
            }
          } else {
            my $k22 = (|(!$in-array ?? @path !! ()), $k, x-to-toml($ks, :key)).join('.');
            $out ~= $k22
                  ~ ' = '
                  ~ x-to-toml($obj{$key}{$ks}, path => (|(!$in-array ?? @path !! ()), $k, x-to-toml($ks)), :$in-array, array-space => $k22.chars + 4)
                  ~ "\n";
          }
        }
      }
    } elsif $obj{$key} ~~ Array && $obj{$key}.elems && $obj{$key}[0] ~~ Hash {
      #make nice array tables
      for |$obj{$key} -> $k2 {
        $out ~= sprintf("[[%s]]\n", (|@path, $k).join('.'));
        $out ~= x-to-toml($k2, path => (|@path, $k), :in-array);
      }
    } else {
      $out ~= "$k = " ~ x-to-toml($obj{$key}, path => (|(!$in-array ?? @path !! ()), $k), :$in-array, array-space => $k.chars + 4) ~ "\n";
    }
  }
  $out;
}
