use Test::More;

use lib 'tools';
use Modsec2LRW qw(parse_operator);

is_deeply(
	parse_operator('foo'),
	{
		operator => 'rx',
		pattern  => 'foo',
	},
	'default operator is rx'
);

is_deeply(
	parse_operator('@rx foo'),
	{
		operator => 'rx',
		pattern  => 'foo',
	},
	'explicity define @rx operator'
);

is_deeply(
	parse_operator('@streq foo'),
	{
		operator => 'streq',
		pattern  => 'foo'
	},
	'define an operator'
);

is_deeply(
	parse_operator('@eq 5'),
	{
		operator => 'eq',
		pattern  => '5',
	},
	'define an operator with a numeric pattern'
);

is_deeply(
	parse_operator('!@rx foo'),
	{
		operator => 'rx',
		pattern  => 'foo',
		negated  => '!'
	},
	'negated operator is defined'
);

is_deeply(
	parse_operator('@detectSQLi'),
	{
		operator => 'detectSQLi',
		pattern  => '',
	},
	'operator with no pattern'
);

is_deeply(
	parse_operator('!@detectSQLi'),
	{
		operator => 'detectSQLi',
		pattern  => '',
		negated  => '!',
	},
	'negated operator with no pattern'
);

is_deeply(
	parse_operator('!foo'),
	{
		operator => 'rx',
		pattern  => 'foo',
		negated  => '!'
	},
	'negated operator is defined when operator is implied'
);

is_deeply(
	parse_operator('! foo'),
	{
		operator => 'rx',
		pattern  => ' foo',
		negated  => '!',
	},
	'space after negation with implicity defined operator'
);

is_deeply(
	parse_operator('! @rx foo'),
	{
		operator => 'rx',
		pattern  => ' @rx foo',
		negated  => '!',
	},
	'space after negation with explicity defined operator'
);

is_deeply(
	parse_operator('! @detectSQLi'),
	{
		operator => 'rx',
		pattern  => ' @detectSQLi',
		negated  => '!',
	},
	'space after negation with no pattern'
);

done_testing;
