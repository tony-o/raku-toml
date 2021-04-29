unit module TOML::NQP;
use TOML::Time;
use nqp;

sub parse-toml(Str() $text) is export(:DEFAULT, :TEST) {
  my $*tld = {};
  my $*tml  = $*tld;
  my %*keys-used;
  my int $pos=0;
  my int $s=0;
  my str $txt=$text;
  my $kv;
  eat-ws($txt, $pos, :all);
  while parse-comment($txt, $pos)
     || defined($kv = parse-keyval($txt, $pos))
     || parse-table($txt, $pos) {
    repeat {
      $s = $pos;
      eat-ws($txt, $pos, :all);
      parse-comment($txt, $pos);
    } while $pos != $s;
    if $kv {
      my $*ptr := $*tml;
      $*ptr := $*ptr{$kv[$_]} for 0 ..^ $kv.elems - 1;
      die 'key is already assigned' if $*ptr.defined;
      $*ptr = $kv[*-1];
    }
    $kv = Nil;
  }
  eat-ws($txt, $pos, :all);
  return Nil if $pos < nqp::chars($txt);
  return $*tld;
}

sub parse-table(str $t, int $pos is rw) is export(:TEST) {
  my int $s = $pos;
  my @parts = (|parse-array-table($t, $pos)).grep(*.defined);
  if @parts.elems {
    $*tml := $*tld;
    for 0 ..^ @parts {
      $*tml := $*tml ~~ List ?? $*tml[*-1]{@parts[$_]} !! $*tml{@parts[$_]};
    }
    die if $*tml ~~ Hash;
    $*tml.push: {};
    $*tml := $*tml[*-1];
    eat-ws($t, $pos);
    $pos=$s, return Nil unless nqp::ordat($t, $pos) == 0xA;
    return True;
  } elsif ((@parts = (|parse-std-table($t, $pos)).grep(*.defined)).elems) {
    $*tml := $*tld;
    for 0 ..^ @parts {
      $*tml := $*tml ~~ List ?? $*tml[*-1]{@parts[$_]} !! $*tml{@parts[$_]};
    }
    die 'key was already used' if $*tml.defined && $*tml !~~ Hash|Array || $*tml ~~ Hash && $*tml.keys == 0;
    $*tml //= {};
    eat-ws($t, $pos);
    $pos=$s, return Nil unless nqp::ordat($t, $pos) == 0xA || $pos >= nqp::chars($t);
    return True;
  }
  $pos = $s;
  Nil;
}

sub parse-array-table(str $t, int $pos is rw) is export(:TEST) {
  return Nil unless nqp::substr($t, $pos, 2) eq '[[';
  my int $s = $pos;
  $pos += 2;
  eat-ws($t, $pos);
  my $key = parse-key($t, $pos);
  $pos=$s, return Nil unless defined($key);
  eat-ws($t, $pos);
  $pos=$s, return Nil unless nqp::substr($t, $pos, 2) eq ']]';
  $pos += 2;
  $key = [$key] if $key !~~ List;
  $key;
}


sub parse-std-table(str $t, int $pos is rw) is export(:TEST) {
  return Nil unless nqp::ordat($t, $pos) == 0x5B;
  my int $s = $pos++;
  eat-ws($t, $pos);
  my $key = parse-key($t, $pos);
  $pos=$s, return Nil unless defined($key);
  eat-ws($t, $pos);
  $pos=$s, return Nil unless nqp::ordat($t, $pos++) == 0x5D;
  $key = [$key] if $key !~~ List;
  $key;
}

sub parse-keyval(str $t, int $pos is rw, :$inline = False) is export(:TEST) {
  my int $s = $pos;
  eat-ws($t, $pos, :all);
  my $key = parse-key($t, $pos);
  $pos=$s, return Nil unless defined $key;
  eat-ws($t, $pos);
  $pos=$s, return Nil unless nqp::ordat($t, $pos++) == 0x3D;
  eat-ws($t, $pos);
  my $val = parse-value($t, $pos);
  $pos=$s, return Nil unless defined $val;
  eat-ws($t, $pos);
  if !$inline {
    $pos=$s, return Nil if $pos < nqp::chars($t) && nqp::ordat($t, $pos) !~~ (0xA|0xD);
    $pos++;
  }
  [|$key, $val];
  #return {$key => $val} if $key !~~ List;
  #my $a  = {};
  #my $b := $a;
  #$b := $b{$key[$_]} for 0..^$key.elems; 
  #$b = $val;
  #$a;
}

sub parse-inline-table(str $t, int $pos is rw) is export(:TEST) {
  return Nil unless nqp::ordat($t, $pos) == 0x7B;
  my int $s = $pos;
  $pos++;
  eat-ws($t, $pos);
  my (%r, $v);
  while defined($v = parse-keyval($t, $pos, :inline)) {
    %r = (|%r, |$v);
    eat-ws($t, $pos);
    last if nqp::ordat($t, $pos) == 0x7D;
    if nqp::ordat($t, $pos) == 0x2C {
      $pos++;
      eat-ws($t, $pos);
      last if nqp::ordat($t, $pos) == 0x7D;
    } else {
      $pos = $s;
      return Nil;
    }
  }
  $pos++; #eat the '}'
  %r;
}

sub parse-array(str $t, int $pos is rw) is export(:TEST) {
  return Nil unless nqp::ordat($t, $pos) == 0x5B;
  my int $s = $pos;
  my int $p = $pos;
  $pos++;
  eat-ws($t, $pos, :all);
  my (@vs, $v);
  while defined($v = parse-value($t, $pos)) {
    @vs.push: $v;
    die 'arrays must be of same type' unless $v.WHAT ~~ @vs[0].WHAT;
    repeat {
      $p = $pos;
      eat-ws($t, $pos, :all);
      parse-comment($t, $pos);
    } while $pos != $p;
    last if nqp::ordat($t, $pos) == 0x5D;
    if nqp::ordat($t, $pos) == 0x2C {
      $pos++;
      eat-ws($t, $pos, :all);
      last if nqp::ordat($t, $pos) == 0x5D;
    } else {
      $pos = $s;
      return Nil;
    }
  }
  $pos++;
  @vs;
}

sub parse-value(str $t, int $pos is rw) is export(:TEST) {
    parse-string($t, $pos)
  //parse-boolean($t, $pos)
  //parse-array($t, $pos)
  //parse-inline-table($t, $pos)
  //parse-date($t, $pos)
  //parse-float($t, $pos)
  //parse-integer($t, $pos);
}

sub eat-ws(str $t, int $pos is rw, :$all = False) is export(:TEST) {
  my $ord = nqp::ordat($t, $pos);
  while $ord ~~ (0x20|0x9)
     || ($all && $ord ~~ (0xA|0xD)) {
    $ord = nqp::ordat($t, ++$pos);
    if $ord == 0x23 {
      $pos++ while $pos < nqp::chars($t) && nqp::ordat($t, $pos) != 0xA;
      $ord = nqp::ordat($t, $pos);
    }
  }
}

sub parse-comment(str $t, int $pos is rw) is export(:TEST) {
  return Nil if nqp::ordat($t, $pos) != 0x23;
  my $ord = nqp::ordat($t, $pos);
  my int $s = $pos;
  while $ord == 0x09
     || 0x20 <= $ord <= 0x7F
     || 0x80 <= $ord <= 0xD7FF
     || 0xE000 <= $ord <= 0x10FFFF {
    $ord = nqp::ordat($t, ++$pos);
    last if $pos > nqp::chars($t);
  }
  nqp::substr($t, $s, $pos++ - $s);
}

sub parse-key(str $t, int $pos is rw) is export(:TEST) {
  my int $s = $pos;
  my $key = parse-basic-string($t, $pos) // parse-literal-string($t, $pos);
  if !defined $key {
    # do unquoted
    my $ord = nqp::ordat($t, $pos);
    while 0x41 <= $ord <= 0x5A
       || 0x61 <= $ord <= 0x7A
       || 0x30 <= $ord <= 0x39
       || $ord ~~ (0x2D|0x5F) {
    
      $ord = nqp::ordat($t, ++$pos);
    }
    $key = nqp::substr($t, $s, $pos - $s) if $pos != $s;
  }
  $pos = $s, return Nil unless defined $key;
  $s = $pos;
  $s++ while $s < nqp::chars($t) && nqp::ordat($t, $s) ~~ (0x30);
  if nqp::ordat($t, $s) == 0x2E {
    $pos = $s+1;
    return $key, |parse-key($t, $pos);
  }
  $key;
}

sub parse-string(str $t, int $pos is rw) is export(:TEST) {
  parse-ml-basic-string($t, $pos) //
  parse-basic-string($t, $pos) //
  parse-ml-literal-string($t, $pos) //
  parse-literal-string($t, $pos);
}

sub parse-time-part(str $t, int $pos is rw) is export(:TEST) {
  my @part;
  my int $s = $pos;
  @part.push: parse-integer($t, $pos, :only-dec, :zero-ok);
  $pos = $s, return Nil if !defined(@part[*-1])
                        || $pos - $s != 2
                        || nqp::ordat($t, $pos++) != 0x3A;
  @part.push: parse-integer($t, $pos, :only-dec, :zero-ok);
  $pos = $s, return Nil if !defined(@part[*-1])
                        || $pos - $s != 5
                        || nqp::ordat($t, $pos++) != 0x3A;
  @part.push: parse-float($t, $pos, :zero-ok) // parse-integer($t, $pos, :only-dec, :zero-ok);
  my $pp = $pos - $s - 8;
  return @part if $pos - $s == 8 + $pp
               &&($pos >= nqp::chars($t)
               || nqp::ordat($t, $pos) ~~ (0x20|0xA|0xC));
  $pos = $s, return Nil if !defined(@part[*-1])
                        || $pos - $s != 8 + $pp
                        || nqp::ordat($t, $pos++) !~~ (0x5A|0x2B|0x2D);
  return @part if nqp::ordat($t, $pos-1) == 0x5A;
               &&($pos >= nqp::chars($t)
               || nqp::ordat($t, $pos) ~~ (0x20|0xA|0xC));
  my $tzf = nqp::ordat($t, $pos - 1) == 0x2B ?? 1 !! -1; 
  @part.push: parse-integer($t, $pos, :only-dec, :zero-ok);
  $pos = $s, return Nil if !defined(@part[*-1])
                        || $pos - $s != 11 + $pp
                        || nqp::ordat($t, $pos++) != 0x3A;
  @part.push: parse-integer($t, $pos, :only-dec);
  $pos = $s, return Nil if !defined(@part[*-1])
                        || $pos - $s != 14 + $pp
                        ||($pos < nqp::chars($t)
                        && nqp::ordat($t, $pos) !~~ (0x20|0xA|0xC));
  my $timezone  = @part.pop * 60;
     $timezone += @part.pop * 3600;
     $timezone *= $tzf;
  @part.push: $timezone;
  return @part;
}

sub parse-date(str $t, int $pos is rw) is export(:TEST) {
  my int $s = $pos;
  my @part;
  @part[0] = parse-integer($t, $pos, :only-dec);
  $pos = $s, return Nil if !defined(@part[0])
                        ||($pos - $s != 4
                        &&$pos - $s != 2);
  if $pos - $s == 4 {
    $pos = $s, return Nil if nqp::ordat($t, $pos) != 0x2D;
    $pos++;
    @part[1] = parse-integer($t, $pos, :only-dec, :zero-ok);
    $pos = $s, return Nil if !defined(@part[1])
                          || $pos - $s != 7
                          || nqp::ordat($t, $pos++) != 0x2D;
    @part[2] = parse-integer($t, $pos, :only-dec, :zero-ok);
    return Date.new(|@part) if $pos - $s == 10
                            &&($pos >= nqp::chars($t)
                            || nqp::ordat($t, $pos) ~~ (0x20|0xA|0xC));
    $pos = $s, return Nil if !defined(@part[2])
                          || $pos - $s != 10
                          || nqp::ordat($t, $pos++) != 0x54;
    @part.push: |parse-time-part($t, $pos);
    $pos = $s, return Nil if !defined(@part[3])
                          && nqp::ordat($t, $pos) !~~ (0x20|0xA|0xC);
    return DateTime.new(|@part) if @part == 6;
    return DateTime.new(|@part, :timezone(@part.pop));
  } elsif $pos - $s == 2 { 
    $pos = $s;
    @part = parse-time-part($t, $pos);
    $pos = $s, return Nil if @part < 3;
    return TOML::Time.new(|@part); 
  }
  $pos = $s;
  return Nil;
}

sub eat-newline(str $t, $pos is rw) {
  $pos++ while is-newline($t, $pos);
}

sub is-newline(str $t, $pos) is export(:TEST) {
  return True if nqp::ordat($t, $pos) ~~ 0xD|0xA;
  False;
}

sub is-literal-char(str $t, $pos) is export(:TEST) {
  my int $o = nqp::ordat($t, $pos);
  return True if $o == 0x09           || (0x20 <= $o <= 0x26)
              || (0x28 <= $o <= 0x7E) || is-non-ascii($t, $pos);
  False;
}

sub is-non-ascii(str $t, $pos) is export(:TEST) {
  my int $o = nqp::ordat($t, $pos);
  return True if (0x80 <= $o <= 0xD7FF)
              || (0xE000 <= $o <= 0x10FFFF);
  False;
}

sub parse-ml-literal-string(str $t, $pos is rw) is export(:TEST) {
  return Nil if nqp::substr($t, $pos, 3) ne '\'\'\'';
  $pos += 3;
  eat-newline($t, $pos);
  my int $s = $pos;
  $pos++ while $pos < nqp::chars($t)
            && (   is-literal-char($t, $pos)
                || is-newline($t, $pos)
                || (nqp::ordat($t, $pos) == 0x27 && nqp::substr($t, $pos, 3) ne '\'\'\''));
  die "literal string not terminated, started @ $s" if $pos >= nqp::chars($t)
                                                    || nqp::substr($t, $pos, 3) ne '\'\'\'';
  $pos += 3;
  nqp::substr($t, $s, $pos - $s - 3);
}

sub parse-ml-basic-string(str $t, $pos is rw) is export(:TEST) {
  return Nil if nqp::substr($t, $pos, 3) ne '"""';
  $pos += 3;
  eat-newline($t, $pos);
  my int $s = $pos;
  my int $r;
  my str $str = '';
  while $pos < nqp::chars($t)
     && nqp::substr($t, $pos, 3) ne '"""'
     && (   ($r = 1) > 0
         || nqp::ordat($t, $pos) == 0x22
         || is-newline($t, $pos)
         || ($r = is-basic-char($t, $pos)) > 0) {
    if nqp::ordat($t, $pos) == 0x5C {
      my $ff = 1;
      $str ~= do given nqp::ordat($t, $pos+1) {
        when 0xA  {
          $pos+=2;
          $pos++ while nqp::ordat($t, $pos) == 0x20|0xA|0xC;
          next;
        }
        when 0x22 { '"'; }
        when 0x5C { "\\"; }
        when 0x62 { "\b"; }
        when 0x66 { "\f"; }
        when 0x6E { "\n"; }
        when 0x72 { "\r"; }
        when 0x74 { "\t"; }
        when 0x75 {
          $ff += 4;
          my $s = ":16<{nqp::substr($t, $pos + 2, 4)}>";
          die if 0xD800 <= $s <= 0xDFFF;
          chr($s);
        }
        when 0x55 {
          $ff += 8;
          my $s = ":16<{nqp::substr($t, $pos + 2, 8)}>";
          chr($s);
        }
        default { die "invalid escape sequence '\\{chr(nqp::ordat($t, $pos+1))}'"; };
      };
      $pos += $ff;
    } else {
      $str ~= chr(nqp::ordat($t, $pos));
    }
    $pos += $r;
  }
  die "basic multiline string not terminated, started @ $s" if $pos >= nqp::chars($t)
                                                            || nqp::substr($t, $pos, 3) ne '"""';
  $pos += 3;
  my int $offset = 0;
  if nqp::ordat($t, $s) == 0x5C {
    $offset++;
    $offset++ while $s+$offset < nqp::chars($t) && nqp::ordat($t, $s+$offset) ~~ (0x20|0xA|0xC);
  }
  #nqp::substr($t, $s + $offset, $pos - $offset - $s - 3);
  $str;
}

sub parse-basic-string(str $t, $pos is rw) is export(:TEST) {
  return Nil if nqp::ordat($t, $pos) != 0x22;
  my int $s = $pos;
  $pos++;
  my int $r;
  my $str = '';
  while $pos < nqp::chars($t) && ($r = is-basic-char($t, $pos)) > 0 {
    if nqp::ordat($t, $pos) == 0x5C {
      my $ff = 0;
      $str ~= do given nqp::ordat($t, $pos+1) {
        when 0xA  {
          $pos+=2;
          $pos++ while nqp::ordat($t, $pos) == 0x20|0xA|0xC;
          next;
        }
        when 0x22 { '"'; }
        when 0x5C { "\\"; }
        when 0x62 { "\b"; }
        when 0x66 { "\f"; }
        when 0x6E { "\n"; }
        when 0x72 { "\r"; }
        when 0x74 { "\t"; }
        when 0x75 {
          $ff = 4;
          my $s = ":16<{nqp::substr($t, $pos + 2, 4)}>";
          die if 0xD800 <= $s <= 0xDFFF;
          chr($s);
        }
        when 0x55 {
          $ff = 8;
          my $s = ":16<{nqp::substr($t, $pos + 2, 8)}>";
          chr($s);
        }
        default { die; }; #chr(nqp::ordat($t, $pos+1)); };
      };
      $pos += $ff;
    } else {
      $str ~= chr(nqp::ordat($t, $pos));
    }
    $pos += $r;
  }
  die "basic string not terminated, started @ $s" if $pos >= nqp::chars($t)
                                                  || nqp::ordat($t, $pos) != 0x22;
  $pos++;
  $str;
}

sub is-basic-char($t, $pos --> int) is export(:TEST) {
  my int $o = nqp::ordat($t, $pos);
  if $o == 0x5C {
    $o = nqp::ordat($t, $pos+1);
    return 2 if $o ~~ 0x22|0x5C|0x62|0x66|0x6E|0x72|0x74|0x75|0x55;
    # TODO: validate the sequence
    return 4 if $o == 0x75;
    return 8 if $o == 0x55;
    die "invalid escape sequence '\\{chr(nqp::ordat($t, $pos))}' @ $pos";
  }
  return 1 if $o ~~ 0x21|0x20|0x9 || (0x23 <= $o <= 0x5B)
           || (0x5D <= $o <= 0x7E) || is-non-ascii($t, $pos);
  0;
}

sub parse-literal-string(str $t, $pos is rw) is export(:TEST) {
  return Nil if nqp::ordat($t, $pos) != 0x27;
  my int $s = $pos;
  $pos++;
  $pos++ while $pos < nqp::chars($t) && is-literal-char($t, $pos);
  die "literal string not terminated, started @ $s" if $pos >= nqp::chars($t)
                                                    || nqp::ordat($t, $pos) != 0x27;
  $pos++;
  nqp::substr($t, $s + 1, $pos - $s - 2);
}


sub parse-boolean(str $t, int $pos is rw) is export(:TEST) {
  $pos+=4, return True if nqp::substr($t, $pos, 4) eq 'true'
                       && ($pos+5 >= nqp::chars($t) || nqp::ordat($t, $pos+4) ~~ (0xA|0x20|0xC));
  $pos+=5, return False if nqp::substr($t, $pos, 5) eq 'false'
                        && ($pos+6 >= nqp::chars($t) || nqp::ordat($t, $pos+5) ~~ (0xA|0x20|0xC));
  Nil;
}

sub parse-float(str $t, int $pos is rw, :$zero-ok = False) is export(:TEST) {
  my $s = $pos;
  if (nqp::ordat($t, $pos) ~~ 0x2D|0x2B && nqp::substr($t, $pos + 1, 3) ~~ 'nan'|'inf')
  || nqp::substr($t, $pos, 3) ~~ 'nan'|'inf' {
    my int $sign = nqp::ordat($t, $pos) == 0x2D ?? -1 !! 1;
    $pos++ if nqp::ordat($t, $pos) ~~ 0x2D|0x2B;
    $pos += 3;
    return $sign * (nqp::substr($t, $pos - 3, 3) eq 'nan' ?? NaN !! Inf);
  }
  my $int-part = parse-integer($t, $pos, :only-dec, :$zero-ok);
  $pos = $s, return Nil unless defined $int-part;
  if nqp::ordat($t, $pos) == 0x2E {
    my int $x = ++$pos;
    $pos++ while (0x30 <= nqp::ordat($t, $pos) <= 0x39)
              || nqp::ordat($t, $pos) == 0x5F;
    die "decimal must have numbers following @ $pos" if $x == $pos;
    die "float cannot end with _ @ {$pos-1}" if nqp::ordat($t, $pos - 1) == 0x5F;
    return +(nqp::substr($t, $s, $pos - $s)) if nqp::ordat($t, $pos) !~~ 0x65|0x45;
  }
  if nqp::ordat($t, $pos) ~~ 0x65|0x45 {
    my int $x = ++$pos;
    die "exponent part must contain digits @ $pos" if Nil ~~ parse-integer($t, $pos, :only-dec)
                                                   || $x == $pos;
    return +(nqp::substr($t, $s, $pos - $s));
  }

  $pos = $s;
  return Nil;
}

sub parse-integer(str $t, int $pos is rw, Bool :$zero-ok = False, Bool :$only-dec = False) is export(:TEST) {
  my int $s  = $pos;
  my int $sn = nqp::ordat($t, $pos) == 0x2D ?? -1 !! 1;
  $pos++ if nqp::ordat($t, $pos) ~~ 0x2D|0x2B;
  if nqp::substr($t, $pos, 2) eq '0x' && !$only-dec {
    die 'signs on hex numbers are verboten' unless $pos == $s;
    $pos += 2;
    die 'hex cannot start with _' if nqp::ordat($t, $pos) == 0x5F;
    $pos++ while (0x30 <= nqp::ordat($t, $pos) <= 0x39)
              || (0x41 <= nqp::ordat($t, $pos) <= 0x46)
              || nqp::ordat($t, $pos) == 0x5F;
    #if $pos + 1 < nqp::chars($t) && nqp::ordat($t, $pos+1) !~~ (0x20|0xA|0xC|0x7D|0x5D) {
    #  $pos = $s;
    #  return Nil;
    #}
    return +nqp::substr($t, $s, $pos - $s);
  } elsif nqp::substr($t, $pos, 2) eq '0b' && !$only-dec {
    die 'signs on hex numbers are verboten' unless $pos == $s;
    $pos += 2;
    die 'bin cannot start with _' if nqp::ordat($t, $pos) == 0x5F;
    $pos++ while (0x30 <= nqp::ordat($t, $pos) <= 0x31)
              || nqp::ordat($t, $pos) == 0x5F;
    return +nqp::substr($t, $s, $pos - $s);
  } elsif nqp::substr($t, $pos, 2) eq '0o' && !$only-dec {
    die 'signs on octal numbers are verboten' unless $pos == $s;
    $pos += 2;
    die 'octal cannot start with _' if nqp::ordat($t, $pos) == 0x5F;
    $pos++ while (0x30 <= nqp::ordat($t, $pos) <= 0x38)
              || nqp::ordat($t, $pos) == 0x5F;
    return +nqp::substr($t, $s, $pos - $s);
  } elsif 0x30 <= nqp::ordat($t, $pos) <= 0x39 {
    $pos++;
    $pos++ while 0x30 <= nqp::ordat($t, $pos) <= 0x39
              || nqp::ordat($t, $pos) == 0x5F;
    die "number cannot be zero padded @ $pos" if (nqp::ordat($t, $s) == 0x30 || (nqp::ordat($t, $s) ~~ 0x2D|0x2B && nqp::ordat($t, $s+1) == 0x30))
                                              && 1 * nqp::substr($t, $s, $pos - $s) != 0
                                              && !$zero-ok;
    return 1 * nqp::substr($t, $s, $pos - $s);
  }
  $pos = $s;
  Nil;
}
