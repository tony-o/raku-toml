use TOML::NQP :TEST;
use TOML::Time;
use Test;

plan 102;

my int $pos = 0;

is parse-toml("thevoid=[[[[[],],],],]"), {thevoid => [[[[[]]]]]};
is parse-toml("[[a]]\n[[a]]\n"), { a => [{}, {},] };
dies-ok { parse-toml("[[a]]\n[b]\n[b]") };
is parse-toml("[[a]]\na=5\n[[a]]\n"), { a => [{ a=> 5}, {},] };

# std-table
$pos=0 or is parse-array-table('[[ a.b.c ]]', $pos), [qw<a b c>];
$pos=0 or is parse-array-table('[["hello world"]]', $pos), ['hello world'];

# std-table
$pos=0 or is parse-std-table('[ a.b.c ]', $pos), [qw<a b c>];
$pos=0 or is parse-std-table('["hello world"]', $pos), ['hello world'];

# array
$pos=0 or is parse-array('[ 5, 6, 7, ]', $pos), [5,6,7];
$pos=0 or is parse-array('[5, 6, 7,]', $pos), [5,6,7];
$pos=0 or is parse-array('[5, 6, 7]', $pos), [5,6,7];
$pos=0 or is parse-array('[5, 6, 7 ]', $pos), [5,6,7];
$pos=0 or dies-ok { parse-array('[5.5, 6]', $pos); };

# inline-table
$pos=0 or is parse-inline-table('{ a = 5, b = 6 }', $pos), {a => 5, b => 6};
$pos=0 or is parse-inline-table('{ a = 5, b = 6, }', $pos), {a => 5, b => 6};
$pos=0 or is parse-inline-table('{ a = 5_0, b = 6, }', $pos), {a => 50, b => 6};
$pos=0 or is parse-inline-table('{ a = 0x1, b = 6.66, }', $pos), {a => 1, b => 6.66};
$pos=0 or is parse-inline-table('{ a = 0x1, b = "hello world"}', $pos), {a => 1, b => 'hello world'};

# kv
$pos=0 or is parse-keyval('a = 500', $pos), ['a', 500];
$pos=0 or is parse-keyval('a.b = 500', $pos), ['a','b',500],;
$pos=0 or is parse-keyval('a.b = { a = 666 }', $pos), ['a','b',{a => 666} ];

# comments
$pos=0 or is parse-comment('# hello world!', $pos), '# hello world!';
$pos=0 or is parse-comment("# hello world!\nsomething", $pos), '# hello world!';

# keys
$pos=0 or is parse-key('"hello world".abc', $pos), ['hello world', 'abc'];
$pos=0 or is parse-key('hello.world', $pos), [qw<hello world>];
$pos=0 or is parse-key('hello', $pos), [qw<hello>];
$pos=0 or is parse-key('-ab', $pos), [qw<-ab>];
$pos=0 or is parse-key('àb', $pos), Nil;
ok $pos == 0;
$pos=0 or ok parse-key('abàb', $pos) eq 'ab';
$pos=0 or is parse-key('a.b.c.d.e.f.g.h', $pos), [qw<a b c d e f g h>];
$pos=0 or is parse-key('0abc9', $pos), '0abc9';

# string...
$pos=0 or is parse-string("'hello world'", $pos), 'hello world';
$pos=0 or is parse-string("'''hello world'''", $pos), 'hello world';
$pos=0 or is parse-string("'''\\u1234hello world'''", $pos), '\u1234hello world';
$pos=0 or is parse-string("'\\u1234hello world'", $pos), '\u1234hello world';
$pos=0 or is parse-string("\"\"\"\\\n    hello world\n\"\"\"", $pos), "hello world\n";
$pos=0 or is parse-string("\"\"\"\\\n    \n\n\n\n\n hello world\n\"\"\"", $pos), "hello world\n";
$pos=0 or is parse-string('"\u1234hello world"', $pos), "ሴhello world";
$pos=0 or is parse-string('"""\u1234hello world"""', $pos), "ሴhello world";

$pos=0 or ok !defined parse-date('200-01-01', $pos);
$pos=0 or is parse-date('2010-01-01', $pos), Date.new(2010,1,1);
$pos=0 or dies-ok { parse-date('2010-01-00', $pos) };
$pos=0 or dies-ok { parse-date('2011-00-01', $pos) };
$pos=0 or is parse-date('2001-01-01T15:33:00', $pos), DateTime.new(2001,1,1,15,33,0);
$pos=0 or dies-ok { parse-date('2001-01-01T25:33:00', $pos) };
$pos=0 or is parse-date('2001-01-01T15:33:00Z', $pos), DateTime.new(2001,1,1,15,33,0,:offset(0));
$pos=0 or is parse-date('2001-01-01T15:33:00+08:00', $pos), DateTime.new(2001,1,1,15,33,0,:timezone(8 * 60 * 60));
$pos=0 or is parse-date('2001-01-01T15:33:00.000001-08:00', $pos), DateTime.new(2001,1,1,15,33,0.000001,:timezone(8 * -60 * 60));

$pos=0 or is parse-date('15:13:12', $pos).gist, TOML::Time.new(hour => 15, minute => 13, second => 12).gist;
$pos=0 or is parse-date('15:13:12Z', $pos).gist, TOML::Time.new(hour => 15, minute => 13, second => 12,:offset(0)).gist;
$pos=0 or is parse-date('15:13:12+04:30', $pos).gist, TOML::Time.new(hour => 15, minute => 13, second => 12,:offset(16200)).gist;
$pos=0 or dies-ok { parse-date('25:13:12+04:30', $pos) };
$pos=0 or dies-ok { parse-date('00:60:12+04:30', $pos) };
$pos=0 or dies-ok { parse-date('00:59:60+04:30', $pos) };
$pos=0 or dies-ok { parse-date('00:59:59.99999999999999+14:01', $pos) };
$pos=0 or dies-ok { parse-date('00:59:59.99999999999999-12:01', $pos) };
$pos=0 or is parse-date('00:00:00+14:00', $pos).gist, TOML::Time.new(0,0,0,50400).gist;
$pos=0 or is parse-date('00:00:00-12:00', $pos).gist, TOML::Time.new(0,0,0,-43200).gist;


# bool
$pos=0 or is parse-boolean('true', $pos), True;
ok $pos == 4;
$pos=0 or is parse-boolean('false', $pos), False;
ok $pos == 5;
$pos=0 or ok !defined parse-boolean('fals', $pos);
ok $pos == 0;
$pos=0 or ok !defined parse-boolean('trueee', $pos);
ok $pos == 0;
$pos=0 or ok !defined parse-boolean('tru', $pos);
ok $pos == 0;
$pos=0 or ok !defined parse-boolean('falseee', $pos);
ok $pos == 0;

# float
$pos=0 or is parse-float('0.555', $pos), .555;
$pos=0 or ok !defined parse-float('.555', $pos);
$pos=0 or dies-ok { parse-float('0.555_', $pos) };
$pos=0 or dies-ok { parse-float('0._555', $pos) };
$pos=0 or is parse-float('0.5_5_5', $pos), .555;
$pos=0 or is parse-float('100.5_5_5', $pos), 100.555;
$pos=0 or parse-float('0x5.5', $pos);
ok $pos == 0;

# integers
$pos=0 or ok 555 == parse-integer("555", $pos);
$pos=0 or dies-ok { parse-integer('55_', $pos) };
$pos=0 or ok !defined parse-integer('_55', $pos);
$pos=0 or ok $pos == 0;
$pos=0 or ok 55 == parse-integer('5_5', $pos);
ok $pos == 3;
$pos=0 or ok 666 == parse-integer('6_6_6', $pos);
$pos=0 or is parse-integer('55.55', $pos), 55;
$pos=0 or ok 10 == parse-integer('0xA', $pos);
$pos=0 or ok 10 == parse-integer('0x000000000A', $pos);
$pos=0 or dies-ok { parse-integer('0x000000000A_', $pos) };
$pos=0 or ok 10 == parse-integer('0x000000000_A', $pos);
$pos=0 or dies-ok { parse-integer('0x000000000__A', $pos) };
$pos=0 or dies-ok { parse-integer('0x_000000000_A', $pos) };
$pos=0 or ok 9 == parse-integer('0o11', $pos);
$pos=0 or ok 9 == parse-integer('0o1_1', $pos);
$pos=0 or dies-ok { parse-integer('0o_1', $pos) };
$pos=0 or dies-ok { parse-integer('-0o1', $pos) };
$pos=0 or dies-ok { parse-integer('+0o1', $pos) };
$pos=0 or dies-ok { parse-integer('-0x1', $pos) };
$pos=0 or dies-ok { parse-integer('+0x1', $pos) };
$pos=0 or dies-ok { parse-integer('-0b1', $pos) };
$pos=0 or dies-ok { parse-integer('+0b1', $pos) };
$pos=0 or ok 255 == parse-integer('0b000_1111_1111', $pos);
