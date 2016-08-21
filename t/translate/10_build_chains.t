use Test::More;

use lib 'tools';
use Modsec2LRW qw(build_chains);

my @out;

@out = build_chains(
	{
		actions => [ { action => 'foo'} ],
		things  => [ qw(rule1) ],
	}
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [{ action => 'foo', }],
				things  => [ qw (rule1) ],
			}
		]
	],
	'single rule'
);

@out = build_chains(
	{
		actions => [ { action => 'foo' } ],
		things  => [ qw(rule1) ],
	},
	{
		actions => [ { action => 'foo' } ],
		things  => [ qw(rule2) ],
	}
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule1) ],
			},
		],
		[
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule2) ],
			}
		]
	],
	'two individual rules'
);

@out = build_chains(
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule1) ],
	},
	{
		actions => [ { action => 'foo'} ],
		things  => [ qw(rule2) ],
	}
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule1) ],
			},
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule2) ],
			},
		]
	],
	'two rules creating one chain'
);

@out = build_chains(
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule1) ],
	},
	{
		actions => [ { action => 'foo'} ],
		things  => [ qw(rule2) ],
	},
	{
		actions => [ { action => 'bar'} ],
		things  => [ qw(rule3) ],
	},
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule1) ],
			},
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule2) ],
			},
		],
		[
			{
				actions => [ { action => 'bar' } ],
				things  => [ qw(rule3) ],
			},
		]
	],
	'two rules creating a chain, followed by a single rule'
);

@out = build_chains(
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule1) ],
	},
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule2) ],
	},
	{
		actions => [ { action => 'foo'} ],
		things  => [ qw(rule3) ],
	},
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule1) ],
			},
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule2) ],
			},
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule3) ],
			},
		]
	],
	'three rules creating one chain'
);

@out = build_chains(
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule1) ],
	},
	{
		actions => [ { action => 'foo'} ],
		things  => [ qw(rule2) ],
	},
	{
		actions => [ { action => 'chain'} ],
		things  => [ qw(rule3) ],
	},
	{
		actions => [ { action => 'bar'} ],
		things  => [ qw(rule4) ],
	},
);
is_deeply(
	\@out,
	[
		[
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule1) ],
			},
			{
				actions => [ { action => 'foo' } ],
				things  => [ qw(rule2) ],
			},
		],
		[
			{
				actions => [ { action => 'chain' } ],
				things  => [ qw(rule3) ],
			},
			{
				actions => [ { action => 'bar' } ],
				things  => [ qw(rule4) ],
			},
		]
	],
	'four rules creating two chains'
);

done_testing;
