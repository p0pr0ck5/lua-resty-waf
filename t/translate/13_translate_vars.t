use Test::More;
use Test::Exception;

use lib 'tools';
use Modsec2LRW qw(translate_vars);

my $translation;

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'REQUEST_METHOD',
				specific => '',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type => 'METHOD',
		}
	],
	'translate a var in the lookup table'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => '',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type  => 'REQUEST_ARGS',
			parse => [ qw(values 1) ],
		}
	],
	'translate a var in the lookup table with a parse helper'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => 'foo',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type  => 'REQUEST_ARGS',
			parse => [ qw(specific foo) ],
		}
	],
	'translate a var in the lookup table with a specific value'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'IP',
				specific => 'foo',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type    => 'IP',
			parse   => [ qw(specific FOO) ],
			storage => 1
		}
	],
	'translate a storage var in the lookup table (specific element is uppercased)'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => '',
				modifier => '&'
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type   => 'REQUEST_ARGS',
			parse  => [ qw(values 1) ],
			length => 1,
		}
	],
	'translate a var in the lookup table with a length modifier'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => 'foo',
				modifier => '&'
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type   => 'REQUEST_ARGS',
			parse  => [ qw(specific foo) ],
			length => 1,
		}
	],
	'translate a var in the lookup table with a specific value and a length modifier'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => '/foo/',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type  => 'REQUEST_ARGS',
			parse => [ qw(regex foo) ],
		}
	],
	'translate a var in the lookup table with a specific regex value'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => '/foo/',
				modifier => '!',
			},
		],
	},
	$translation,
	undef,
);
is_deeply(
	$translation->{vars},
	[
		{
			type  => 'REQUEST_ARGS',
			parse => [ qw(ignore_regex foo) ],
		}
	],
	'translate a var in the lookup table ignoring a specific regex value'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => '/foo/',
			},
		],
	},
	$translation,
	undef,
);
is(
	$translation->{vars}->[0]->{parse}->[1],
	'foo',
	'slash-only regex specific wrapper is removed'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => "'/foo/'",
			},
		],
	},
	$translation,
	undef,
);
is(
	$translation->{vars}->[0]->{parse}->[1],
	'foo',
	'quote and slash regex specific wrapper is removed'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'ARGS',
				specific => 'fo/o',
			},
		],
	},
	$translation,
	undef,
);
is(
	$translation->{vars}->[0]->{parse}->[1],
	'fo/o',
	'specific element does not have slash removed when its not a wrapper'
);

dies_ok(
	sub {
		translate_vars(
			{
				vars => [
					{
						variable => 'FOO',
						specific => '',
					},
				],
			},
			$translation,
			undef,
		);
	},
	'dies when a variable cannot be found in the lookup table'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'FOO',
				specific => '',
			},
		],
	},
	$translation,
	1,
);
is_deeply(
	$translation->{vars},
	undef,
	'translation failure does not die when force is set'
);

dies_ok(
	sub {
		translate_vars(
			{
				vars => [
					{
						variable => 'FOO',
						specific => '',
					},
					{
						variable => 'REQUEST_METHOD',
						specific => '',
					}
				],
			},
			$translation,
			undef,
		);
	},
	'dies when one of several variables cannot be found in the lookup table'
);

$translation = {};
translate_vars(
	{
		vars => [
			{
				variable => 'FOO',
				specific => '',
			},
			{
				variable => 'REQUEST_METHOD',
				specific => '',
			}
		],
	},
	$translation,
	1,
);
is_deeply(
	$translation->{vars},
	[
		{
			type => 'METHOD',
		}
	],
	'translation failure does not die when force is set'
);

dies_ok(
	sub {
		translate_vars(
			{
				vars => [
					{
						variable => 'SERVER_NAME',
						specific => 'foo',
					},
				],
			},
			$translation,
			undef,
		);
	},
	'dies when a specific var resolves to an element with a specific helper'
);

dies_ok(
	sub {
		translate_vars(
			{
				vars => [
					{
						variable => 'SERVER_NAME',
						specific => 'foo',
					},
				],
			},
			$translation,
			1,
		);
	},
	'force does not override specific/specific helper collision'
);

done_testing;
