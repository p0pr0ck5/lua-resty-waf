use Test::More;
use Test::Warn;

use lib 'tools';
use Modsec2LRW qw(parse_vars);

my @out;

is_deeply(
	parse_vars('ARGS'),
	[
		{
			variable => 'ARGS',
			specific => '',
		}
	],
	'single var, no modifier or specific'
);

is_deeply(
	parse_vars('ARGS:foo'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
		}
	],
	'single var with specific element'
);

is_deeply(
	parse_vars('ARGS|!ARGS:foo'),
	[
		{
			variable => 'ARGS',
			modifier => '!',
			ignore   => [ 'foo' ],
			specific => '',
		}
	],
	'single var with specific element and negative modifier'
);

is_deeply(
	parse_vars('ARGS|!ARGS:/__foo/'),
	[
		{
			variable => 'ARGS',
			modifier => '!',
			ignore   => [ '/__foo/' ],
			specific => '',
		}
	],
	'single var with specific element and negative regex modifier'
);

is_deeply(
	parse_vars('&ARGS'),
	[
		{
			variable => 'ARGS',
			specific => '',
			modifier => '&'
		}
	],
	'single var with counting modifier'
);

is_deeply(
	parse_vars('&ARGS:foo'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
			modifier => '&'
		}
	],
	'single var with specific element and counting modifier'
);

is_deeply(
	parse_vars('ARGS:foo:bar'),
	[
		{
			variable => 'ARGS',
			specific => 'foo:bar',
		}
	],
	'single var with specific element containing colon'
);

is_deeply(
	parse_vars('ARGS|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => '',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two single elements, no modifiers'
);

is_deeply(
	parse_vars('ARGS:foo|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two single elements, one specific element'
);

is_deeply(
	parse_vars('ARGS:foo|ARGS_NAMES:bar'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
		},
		{
			variable => 'ARGS_NAMES',
			specific => 'bar',
		}
	],
	'two single elements, two specific elements'
);

is_deeply(
	parse_vars('&ARGS:foo|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
			modifier => '&'
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two single elements, one modifier and one specific element'
);

is_deeply(
	parse_vars('ARGS:foo|&ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => 'foo',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
			modifier => '&',
		}
	],
	'two single elements, one modifier, the other with specific element'
);

is_deeply(
	parse_vars('ARGS:/foo/'),
	[
		{
			variable => 'ARGS',
			specific => '/foo/',
		}
	],
	'single element with regex specific'
);

is_deeply(
	parse_vars("ARGS:'/foo/'"),
	[
		{
			variable => 'ARGS',
			specific => "'/foo/'",
		}
	],
	'single element with regex specific, quote wrapped'
);

is_deeply(
	parse_vars("ARGS:/fo'o/"),
	[
		{
			variable => 'ARGS',
			specific => "/fo'o/",
		}
	],
	'single element with regex specific, quote in specific'
);

is_deeply(
	parse_vars("ARGS:'/fo'o/'"),
	[
		{
			variable => 'ARGS',
			specific => "'/fo'o/'",
		}
	],
	'single element with regex specific, quote wrapped, quote in specific'
);

is_deeply(
	parse_vars('ARGS:/fo/o/'),
	[
		{
			variable => 'ARGS',
			specific => '/fo/o/',
		}
	],
	'single element with regex specific, quote wrapped'
);

is_deeply(
	parse_vars("ARGS:'/fo/o/'"),
	[
		{
			variable => 'ARGS',
			specific => "'/fo/o/'",
		}
	],
	'single element with regex specific, quote wrapped, slash in specific'
);

is_deeply(
	parse_vars('ARGS:/foo|bar/'),
	[
		{
			variable => 'ARGS',
			specific => '/foo|bar/',
		}
	],
	'single element with regex specific containing pipe'
);

is_deeply(
	parse_vars("ARGS:'/foo|bar/'"),
	[
		{
			variable => 'ARGS',
			specific => "'/foo|bar/'",
		}
	],
	'single element with regex specific containing pipe, quote wrapped'
);

is_deeply(
	parse_vars('ARGS:/foo/|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => '/foo/',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific'
);

is_deeply(
	parse_vars("ARGS:'/foo/'|ARGS_NAMES"),
	[
		{
			variable => 'ARGS',
			specific => "'/foo/'",
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific, quote wrapped'
);

is_deeply(
	parse_vars("ARGS:/fo'o/|ARGS_NAMES"),
	[
		{
			variable => 'ARGS',
			specific => "/fo'o/",
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific, quote in specific'
);

is_deeply(
	parse_vars("ARGS:'/fo'o/'|ARGS_NAMES"),
	[
		{
			variable => 'ARGS',
			specific => "'/fo'o/'",
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific, quote wrapped, quote in specific'
);

is_deeply(
	parse_vars('ARGS:/fo/o/|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => '/fo/o/',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific, slash in specific'
);

is_deeply(
	parse_vars("ARGS:'/fo/o/'|ARGS_NAMES"),
	[
		{
			variable => 'ARGS',
			specific => "'/fo/o/'",
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific, quote wrapped, slash in specific'
);

is_deeply(
	parse_vars('ARGS:/foo|bar/|ARGS_NAMES'),
	[
		{
			variable => 'ARGS',
			specific => '/foo|bar/',
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific containing pipe'
);

is_deeply(
	parse_vars("ARGS:'/foo|bar/'|ARGS_NAMES"),
	[
		{
			variable => 'ARGS',
			specific => "'/foo|bar/'",
		},
		{
			variable => 'ARGS_NAMES',
			specific => '',
		}
	],
	'two elements, one with regex specific containing pipe, quote wrapped'
);

is_deeply(
	parse_vars("REQUEST_HEADERS:'/(Content-Length|Transfer-Encoding)/'"),
	[
		{
			variable => 'REQUEST_HEADERS',
			specific => "'/(Content-Length|Transfer-Encoding)/'"
		}
	],
	'real-life example from CRSv2 (#185)'
);

warning_like
	{
		parse_vars('!ARGS:foo');
	}
	qr/No previous var/,
	'Warn when trying to ignore an element from a previously unseen collection'
;

warning_like
	{
		parse_vars('ARGS_GET|!ARGS:foo');
	}
	qr/Seen var ARGS doesn't match previous var ARGS_GET/,
	'Warn when trying to ignore an element from a mismatched previous collection'
;

done_testing;
