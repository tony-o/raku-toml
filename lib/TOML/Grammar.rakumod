#use Grammar::Tracer::Compact;
unit grammar TOML::Grammar;

rule TOP(%*TOP = {}, $*PTR = ()) { {$*PTR:=%*TOP;}
  ^ <expression>* %% (<newline> <ws>?)+ $
}
token expression {
  |<ws> <comment>
  |<ws> <keyval> <ws> <comment>?
  |<ws> <table> <ws> <comment>?
}
token newline {
  \r? \n
}
token ws {
  <wschar>*
}
token wschar {
  |' '
  |\t
}
token comment {
  '#' <non-eol>*
}
token non-ascii {
  |<[\x[80]..\x[D7FF]]>
  |<[\x[E000]..\x[10FFFF]]>
}
token non-eol {
  |\x[09]
  |<[\x[20]..\x[7f]]>
  |<non-ascii>
}
token keyval {
  <key> <keyval-sep> <val>
}
token key {
  |<dotted-key>
  |<simple-key>
}
token keyval-sep {
  <ws> '=' <ws>
}
token val {
  |<string>
  |<boolean>
  |<array>
  |<inline-table>
  |<date-time>
  |<float>
  |<integer>
}
token table {
  |<array-table>
  |<std-table>
}
token std-table {
  <std-table-open> ~ <std-table-close> <key>
}
token std-table-open { '[' <ws> }
token std-table-close { <ws> ']' }
token array-table {
  <array-table-open> ~ <array-table-close> <key>
}
token array-table-open { '[[' <ws> }
token array-table-close { <ws> ']]' }
token inline-table-open { '{' }
token inline-table-close { '}' }
token inline-table-sep { ',' }
token inline-table {
  <inline-table-open> ~ <inline-table-close> <inline-table-keyvals>?
}
token inline-table-keyvals {
  <ws> <keyval> <ws> [|<inline-table-sep> <inline-table-keyvals>
                      |<inline-table-sep>?]
}
token date-time {
  |<offset-date-time>
  |<local-date-time>
  |<local-date>
  |<local-time>
}
token date-fullyear { <DIGIT> ** 4 }
token date-month { <DIGIT> ** 2 }
token date-mday { <DIGIT> ** 2 }
token time-delim { 'T' }
token time-hour { <DIGIT> ** 2 }
token time-minute { <DIGIT> ** 2 }
token time-second { <DIGIT> ** 2 }
token time-secfrac { '.' <DIGIT>+ }
token time-numoffset { [|'+'|'-'] <time-hour> ':' <time-minute> }
token time-offset { |'Z' |<time-numoffset> }
token partial-time { <time-hour> ':' <time-minute> ':' <time-second> <time-secfrac>? }
token full-date { <date-fullyear> '-' <date-month> '-' <date-mday> }
token full-time { <partial-time> <time-offset> }
token offset-date-time { <full-date> <time-delim> <full-time> }
token local-date-time { <full-date> <time-delim> <partial-time> }
token local-date { <full-date> }
token local-time { <partial-time> }
token boolean {
  |'true'
  |'false'
}
token array {
  <array-open> ~ <array-close> <array-values>
}
token array-values {
  |<ws-comment-newline> <val> <array-sep> <ws-comment-newline> <array-values>
  |<ws-comment-newline> <val> <array-sep>? <ws-comment-newline>
  |<ws-comment-newline>
}
token ws-comment-newline {
  [|<comment>? <newline>
   |<wschar>]*
}
token array-sep { ',' }
token array-open { '[' }
token array-close { ']' }
token string {
  |<ml-basic-string>
  |<basic-string>
  |<ml-literal-string>
  |<literal-string>
}
token ml-basic-string {
  <ml-basic-string-delim> ~ <ml-basic-string-delim> <ml-basic-body>?
}
token ml-literal-string {
  <ml-literal-string-delim> ~ <ml-literal-string-delim> <ml-literal-body>?
}
token ml-basic-body {
  <mlb-content>+ %% <mlb-quotes>?
}
token ml-literal-body {
  <mll-content>+ %% <mll-quotes>?
}
token mll-content {
  |<mll-char>
  |<newline>
}
token mll-char {
  |\x[09]
  |<[\x[20]..\x[26]]>
  |<[\x[28]..\x[7E]]>
  |<non-ascii>
}
token mll-quotes {
  <apostrophe> ** 1..2 <!before <apostrophe>>
}
token mlb-content {
  |<mlb-char>
  |<newline>
  |<mlb-escaped-nl>
}
token mlb-char {
  |<mlb-unescaped>
  |<escaped>
}
token mlb-escaped-nl {
  <escape> <ws> <newline> [|<wschar>|<newline>]*
}
token mlb-quotes {
  <quotation-mark> ** 1..2 <!before <quotation-mark>>
}
token mlb-unescaped {
  |<wschar>
  |\x[21]
  |<[\x[23]..\x[5B]]>
  |<[\x[5D]..\x[7E]]>
  |<non-ascii>
}
token dotted-key {
  <simple-key> <dot-sep> <simple-key>+ %% <dot-sep> 
}
token simple-key {
  |<quoted-key>
  |<unquoted-key>
}
token quoted-key {
  |<basic-string>
  |<literal-string>
}
token unquoted-key {
  [|<ALPHA>|<DIGIT>|\x[2D]|\x[5F]]+
}
token basic-string { <quotation-mark> ~ <quotation-mark> <basic-char>* }
token literal-string { <apostrophe> ~ <apostrophe> <literal-char>* }
token float {
  |<float-int-part> [|<exp>
                     |<frac> <exp>?]
  |<special-float>
}
token frac {
  <decimal-point> <zero-prefixable-int>
}
token zero-prefixable-int {
  <DIGIT>+ <underscore>? %% <zero-prefixable-int>+
}
token float-int-part {
  <dec-int>
}
token exp {
  <exp-char> <float-exp-part>
}
token exp-char { |'e'|'E' }
token special-float {
  [|'-'|'+']? [|'inf'|'nan']
}
token float-exp-part {
  [|'-'|'+']? <zero-prefixable-int>
}
token integer {
  |<dec-int>
  |<hex-int>
  |<oct-int>
  |<bin-int>
}
token dec-int {
  [|'-'|'+']? <unsigned-dec-int>
}
token hex-int {
  <hex-prefix> <HEXDIG>+ %% <underscore> #? <HEXDIG>+
}
token oct-int {
  <oct-prefix> <digit0_7>+ %% <underscore> #? %% <digit0_7>+
}
token bin-int {
  <bin-prefix> <digit0_1>+ %% <underscore> #? %% <digit0_1>+
}
token unsigned-dec-int {
  |<digit1_9> <underscore>? <zero-prefixable-int>?
  |<DIGIT>
}
token literal-char {
  |\x[09]
  |<[\x[20]..\x[26]]>
  |<[\x[28]..\x[7E]]>
  |<non-ascii>
}
token basic-char {
  |<basic-unescaped>
  |<escaped>
}
token basic-unescaped {
  |<wschar>
  |\x[21]
  |<[\x[23]..\x[5B]]>
  |<[\x[5D]..\x[7E]]>
  |<non-ascii>
}
token escaped {
  <escape> <escape-seq-char>
}
token escape-seq-char {
  |\x[22]
  |\x[5C]
  |\x[62]
  |\x[66]
  |\x[6E]
  |\x[72]
  |\x[74]
  |\x[75] <HEXDIG> ** 4
  |\x[55] <HEXDIG> ** 8
}
token dot-sep { <ws> '.' <ws> }
token escape { '\\' }
token decimal-point { '.' }
token hex-prefix { '0x' }
token oct-prefix { '0o' }
token bin-prefix { '0b' }
token digit1_9 { <[1..9]> }
token digit0_7 { <[0..7]> }
token digit0_1 { <[0..1]> }
token apostrophe { '\'' }
token quotation-mark { '"' }
token ml-basic-string-delim  { <quotation-mark> ** 3 }
token ml-literal-string-delim { <apostrophe> ** 3 }
token underscore { '_' }
token ALPHA  { <[a..zA..Z]> }
token DIGIT  { <[0..9]> }
token HEXDIG { |<DIGIT>|<[A..F]> }
