use TOML::Time;
unit role TOML::Actions;

method TOP($/) {
  $/.make: %*TOP;
}

method expression($/) {
  if $/<keyval> {
    my $ptr := $*PTR;
    if $ptr ~~ Array {
      $ptr.push({}) unless + $ptr;
      $ptr := $ptr[*-1];
    }
    if $/<keyval>.made.key ~~ Hash {
      # dotted keys .
      my $kvp := $/<keyval>.made.key;
      while $kvp{$kvp.keys.first}.keys {
        $ptr{$kvp.keys.first} //= {};
        $ptr := $ptr{$kvp.keys.first};
        $kvp := $kvp{$kvp.keys.first};
      }
      die if $ptr{$kvp.keys.first}.defined;
      $ptr{$kvp.keys.first} = $/<keyval>.made.value;
    } else {
      die if $ptr{$/<keyval>.made.key}.defined;
      $ptr{$/<keyval>.made.key} = $/<keyval>.made.value;
    }
  }
}

method std-table($/) {
  if $<key>.made ~~ Str {
    die %*TOP{$<key>.made} if %*TOP{$<key>.made}.defined
                           && %*TOP{$<key>.made} !~~ Hash|Array
                           || (%*TOP{$<key>.made} ~~ Hash && %*TOP{$<key>.made}.keys == 0);
    %*TOP{$<key>.made} //= {};
    $*PTR := %*TOP{$<key>.made};
  } else {
    my $ptr = $<key>.made;
    $*PTR  := %*TOP;
    while $ptr.keys > 0 {
      die 'how did we get here?' if $ptr.keys > 1;
      if $*PTR{$ptr.keys.first} ~~ Array {
        $*PTR{$ptr.keys.first}.push({}) unless + $*PTR{$ptr.keys.first};
        $*PTR := $*PTR{$ptr.keys.first}[*-1];
      } else {
        $*PTR{$ptr.keys.first} //= {};
        $*PTR := $*PTR{$ptr.keys.first};
      }
      $ptr := $ptr{$ptr.keys.first};
    }
    $*PTR //= {};
  }
}
method array-table($/) {
  if $<key>.made ~~ Str {
    if %*TOP{$<key>.made} ~~ Array|List {
      %*TOP{$<key>.made}.push({});
      $*PTR := %*TOP{$<key>.made};
    } else {
      die if %*TOP{$<key>.made}.defined && %*TOP{$<key>.made} !~~ Array;
      %*TOP{$<key>.made} = [];
      $*PTR := %*TOP{$<key>.made};
    }
  } else {
    my $ptr = $<key>.made;
    $*PTR  := %*TOP;
    while $ptr.keys > 0 {
      die 'how did we get here?' if $ptr.keys > 1;
      if $*PTR{$ptr.keys.first} ~~ Array {
        $*PTR{$ptr.keys.first}.push({}) unless + $*PTR{$ptr.keys.first};
        $*PTR := $ptr{$ptr.keys.first}.keys ?? $*PTR{$ptr.keys.first}[*-1] !! $*PTR{$ptr.keys.first};
      } else {
        $*PTR := $*PTR{$ptr.keys.first};
      }
      $ptr := $ptr{$ptr.keys.first};
    }
    $*PTR.push({});
  }
}

method array($/) {
  $/.make: [ $<array-values>.made // () ];
}

method array-values($/) {
  my @a = [];
  @a.push($<val>.made) if $<val>;
  @a.push(|$<array-values>.made) if $<array-values>;
  die if @a.elems >= 2 && @a[0].WHAT !~~ @a[1].WHAT;
  $/.make: @a;
}

method integer($/) {
  die if $/.Str.substr(0,1) eq '_' || $/.Str.substr(*-1) eq '_';
  $/.make: $/.Str.Int;
}

method string($/) {
  $/.make: $<ml-basic-string basic-string ml-literal-string literal-string>.grep(*.defined).first.made;
}

sub interpolate($x) {
  my $str = $x.split('');
  my $idx = 0;
  my $bil = '';
  my $ff;
  while $idx < $str.elems {
    if $str[$idx] eq '\\' {
      $idx++;
      $ff = 0;
      $bil ~= do given $str[$idx] {
        when '"'  { '"';  };
        when '\\' { '\\'; };
        when 'b'  { "\b"; };
        when 'f'  { "\f"; };
        when 'n'  { "\n"; };
        when 'r'  { "\r"; };
        when 't'  { "\t"; };
        when 'u'  {
          $ff = 4;
          my $s = ":16<{$str[$idx+1 .. $idx+$ff].join('')}>".Int;
          die if $s >= 0xD800 && $s <=0xDFFF;
          chr($s);
        }
        when 'U'  {
          $ff = 8;
          chr(":16<{$str[$idx+1 .. $idx+$ff].join('')}>".Int);
        }
      };
      $idx += $ff;
    } else {
      $bil ~= $str[$idx];
    }
    $idx++;
  }
  $bil;
}
sub ml-basic-is-ws($l) { $l ~~ m/^ \s* $/; }
sub ml-basic-is-esc($l) { $l ~~ m/ '\\' \s* $/; }
method ml-basic-string($/) {
  my @lines = ($<ml-basic-body>//'').split($?NL);
  my $str   = '';
  my $state = 0; # 0 = normal, 1 = trimming
  my $idx   = 0;
  for @lines -> $l {
    $idx++;
    if ml-basic-is-esc($l) {
      my $x  = $l.substr(0, $l.rindex('\\'));
      $x    .=trim-leading if $state == 1;
      $str  ~= $x;
      $state = 1;
    } else {
      if $state == 1 && ml-basic-is-ws($l) {
        next;
      } elsif $state == 1 {
        #trim
        $str ~= $l.trim-leading;
        $state = 0;
      } elsif $idx == 1 && $l.chars == 0 {
        next;
      } else {
        $str ~= $l ~ ($idx == +@lines ?? '' !! $?NL);
      }
    }
  }

  $/.make: interpolate($str);
}
method ml-literal-string($/) {
  my $str = $/.Str.substr(3, *-3);
  $str .=substr(1) if $str.substr(0,1) eq "\n";
  $/.make: $str;
}
method basic-string($/) {
  $/.make: interpolate($/.Str.substr(1,*-1));
}
method literal-string($/) {
  $/.make: $/.Str.substr(1,*-1);
}

method simple-key($/) {
  $/.make: $<unquoted-key quoted-key>.grep(*.defined).first.made;
}

method quoted-key($/) {
  $/.make: $<basic-string literal-string>.grep(*.defined).first.made;
}

method unquoted-key($/) {
  $/.make: $/.Str;
}

method key($/) {
  $/.make: $/<simple-key dotted-key>.grep(*.defined).first.made;
}

method dotted-key($/) {
  my $a = {};
  my $p := $a;
  for $<simple-key> {
    $p{$_.made} = {};
    $p := $p{$_.made};
  }
  $/.make($a);
}

method val($/) {
  $/.make: $<float string array boolean inline-table date-time integer>.grep(*.defined).first.made;
}

method inline-table($/) {
  $/.make: $<inline-table-keyvals>.made // {};
}

method boolean($/) {
  $/.make: $/ eq 'true' ?? True !! False;
}

method inline-table-keyvals($/) {
  my $made = $<keyval><key>.made;
  my %hash;
  if $made ~~ Str {
    %hash{$made} = $<keyval><val>.made; 
  }
  if $<inline-table-keyvals>.made {
    %hash{$_} = $<inline-table-keyvals>.made{$_} for $<inline-table-keyvals>.made.keys;
  }
  $/.make: %hash;
}

method date-time($/) {
  $/.make: $<local-time local-date offset-date-time local-date-time>.grep(*.defined).first.made;
}

method local-date-time($/) {
  $/.make: DateTime.new(
    year  => $<full-date>.made.year,
    month => $<full-date>.made.month,
    day   => $<full-date>.made.day,
    hour  => $<partial-time><time-hour>.Str.Int,
    minute => $<partial-time><time-minute>.Str.Int,
    second => "{$<partial-time><time-second>.Str}{($<partial-time><time-secfrac>//'').Str}".Num,
  );
}

method offset-date-time($/) {
  my $t = $<full-time><partial-time>;
  my $offset = $<full-time><time-offset>;
  if $offset.Str eq 'Z' {
    $offset = 0.0;
  } else {
    $offset = $offset<time-numoffset>;
    my $sign = $offset.Str.substr(0,1) eq '-' ?? -1 !! 1;
    $offset  = $offset<time-hour>.Str.Num + ($offset<time-minute>.Str.Num/60);
    $offset *= $sign * 60 * 60;
  }
  $/.make: DateTime.new(
    year  => $<full-date>.made.year,
    month => $<full-date>.made.month,
    day   => $<full-date>.made.day,
    hour  => $t<time-hour>.Str.Int,
    minute => $t<time-minute>.Str.Int,
    second => "{$t<time-second>.Str}{($t<time-secfrac>//'').Str}".Num,
    timezone => $offset,
  );
}

method local-date($/) {
  my $t = $<full-date>;
  $/.make: $<full-date>.made;
}

method full-date($/) {
  $/.make: Date.new(
    year  => $<date-fullyear>.Str.Int,
    month => $<date-month>.Str.Int,
    day   => $<date-mday>.Str.Int,
  );
}

method local-time($/) {
  my $t = $<partial-time>;
  $/.make: TOML::Time.new(
    hour   => $t<time-hour>.Str.Int,
    minute => $t<time-minute>.Str.Int,
    second => "{$t<time-second>.Str}{($t<time-secfrac>//'').Str}".Num,
    offset => 0,
  );
}

method float($mt) {
  my $s = "{$mt.Str}";
  #TODO; this next two lines should be handled by grammar
  die if $s.substr(0,1) eq '_' || $s.substr(*-1) eq '_';
  die if do { $s ~~ m/'_.'|'._'/ ?? True !! False; };
  if $mt<float-int-part> {
    $mt.make: $s.Num;
  } else {
    $mt.make: ($s.substr(0,1) eq '-' ?? -1 !! 1)
           * ($s.index('inf') ?? Inf !! NaN);
  }
}

method keyval($/) {
  $/.make: Pair.new($/<key>.made, $/<val>.made);
}
