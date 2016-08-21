use Test::More;

use lib 'tools';
use Modsec2LRW qw(strip_encap_quotes);

is(
	strip_encap_quotes("'foo'"),
	'foo',
	'single quoted string is stripped',
);

is(
	strip_encap_quotes('"foo"'),
	'foo',
	'double quoted string is stripped'
);

is(
	strip_encap_quotes('foo'),
	'foo',
	'unquoted string is not stripped'
);

is(
	strip_encap_quotes("'foo"),
	"'foo",
	'unbalanced quotes are not stripped (left)'
);

is(
	strip_encap_quotes("foo'"),
	"foo'",
	'unbalanced quotes are not stripped (right)'
);

is(
	strip_encap_quotes("'foo\""),
	"'foo\"",
	'mismatched quotes are not stripped (left)'
);

is(
	strip_encap_quotes("\"foo'"),
	"\"foo'",
	'mismatched quotes are not stripped (right)'
);

is(
	strip_encap_quotes('""foo""'),
	'"foo"',
	'only set of quotes is stripped'
);

done_testing;
