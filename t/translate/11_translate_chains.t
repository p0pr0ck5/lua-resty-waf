use Test::More;
use Test::Warn;
use Test::MockModule;

use lib 'tools';
use Modsec2LRW qw(translate_chains);

my $Mock = Test::MockModule->new('Modsec2LRW');

$Mock->mock(translate_chain => sub {
	my ($args) = @_; 
	my @chain  = @{$args->{chain}};
	my $silent = $args->{silent};
	my $force  = $args->{force};

	# mock a case where we would die
	for my $rule (@chain) {
		die 'translate_chain died a mocking death'
			if $rule->{mockdie};

		die 'translate_chain died a translation death'
			if $rule->{mockfail} && !$force;
	}

	return @chain;
});

$Mock->mock(figure_phase => sub {
	my ($translation) = @_;

	return $translation->{phase} ? $translation->{phase} : 'access';

	return
});

is_deeply(
	translate_chains({
		chains => [],
	}),
	{
		access        => [],
		header_filter => [],
		body_filter   => [],
	},
	'an empty chain hashref returns the skeleton chain hashref'
);

is_deeply(
	translate_chains({
		chains => [
			[
				{
					id    => '12345',
					foo   => 'bar',
					phase => 'access',
				}
			]
		]
	}),
	{
		access => [
			{
				id    => '12345',
				foo   => 'bar',
				phase => 'access',
			}
		],
		header_filter => [],
		body_filter   => [],
	},
	'a single chain with a single rule is translated'
);

warnings_like
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						mockdie  => 1,
						original => 'original 12345'
					}
				]
			],
		})
	}
	[
		qr/translate_chain died a mocking death/,
		qr/original 12345/,
	],
	'die caught and rethrown as a warn on translation fail'
;

warning_is
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						mockdie  => 1,
						original => 'original 12345'
					}
				]
			],
			quiet => 1,
		})
	}
	'translate_chain died a mocking death',
	'die caught and rethrown as a warn on translation fail with quiet set'
;

is_deeply(
	translate_chains({
		chains => [
			[
				{
					id      => '12345',
					foo     => 'bar',
					phase   => 'access',
					mockdie => 1,
				}
			]
		],
		silent => 1,
		quiet  => 1,
	}),
	{
		access        => [],
		header_filter => [],
		body_filter   => [],
	},
	'a failed translation fails silently when silent is set'
);

warnings_like
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						mockfail => 1,
						original => 'original 12345'
					}
				]
			],
		})
	}
	[
		qr/translate_chain died a translation death/,
		qr/original 12345/,
	],
	'die caught and rethrown as a warn on translation fail'
;

warning_is
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						mockfail => 1,
						original => 'original 12345'
					}
				]
			],
			quiet => 1,
		})
	}
	'translate_chain died a translation death',
	'die caught and rethrown as a warn on translation fail with quiet set'
;

is_deeply(
	translate_chains({
		chains => [
			[
				{
					id       => '12345',
					foo      => 'bar',
					phase    => 'access',
					mockfail => 1,
				}
			]
		],
		silent => 1,
		quiet  => 1,
	}),
	{
		access        => [],
		header_filter => [],
		body_filter   => [],
	},
	'a failed translation fails silently when silent is set'
);


is_deeply(
	translate_chains({
		chains => [
			[
				{
					id       => '12345',
					foo      => 'bar',
					phase    => 'access',
					original => 'original 12345'
				},
				{
					id       => '12346',
					foo      => 'bar',
					phase    => 'access',
					mockfail => 1,
					original => 'original 12346'
				},
			]
		],
		silent => 1,
		quiet  => 1,
	}),
	{
		access        => [],
		header_filter => [],
		body_filter   => [],
	},
	'a chain with two rules does not add to the final output when it dies'
);

warnings_like
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						original => 'original 12345'
					},
					{
						id       => '12346',
						foo      => 'bar',
						phase    => 'access',
						mockfail => 1,
						original => 'original 12346'
					}
				]
			],
		})
	}
	[
		qr/translate_chain died a translation death/,
		qr/original 12345/,
		qr/original 12346/,
	],
	'chain translation with multiple rules fails when one rule dies'
;

warning_is
	{
		translate_chains({
			chains => [
				[
					{
						id       => '12345',
						foo      => 'bar',
						phase    => 'access',
						original => 'original 12345'
					},
					{
						id       => '12346',
						foo      => 'bar',
						phase    => 'access',
						mockfail => 1,
						original => 'original 12346'
					}
				]
			],
			quiet => 1,
		})
	}
	'translate_chain died a translation death',
	'chain translation with multiple rules fails when one rule dies'
;

is_deeply(
	translate_chains({
		chains => [
			[
				{
					id    => '12345',
					foo   => 'bar',
					phase => 'access',
				}
			],
			[
				{
					id    => '23456',
					foo   => 'baz',
					phase => 'access',
				}
			]
		]
	}),
	{
		access => [
			{
				id    => '12345',
				foo   => 'bar',
				phase => 'access',
			},
			{
				id    => '23456',
				foo   => 'baz',
				phase => 'access',
				
			}
		],
		header_filter => [],
		body_filter   => [],
	},
	'multiple chains with a single rule are translated'
);

is_deeply(
	translate_chains({
		chains => [
			[
				{
					id       => '12345',
					foo      => 'bar',
					phase    => 'access',
					mockdie  => 1,
					original => 'original 12345',
				}
			],
			[
				{
					id    => '23456',
					foo   => 'baz',
					phase => 'access',
				}
			]
		],
		silent => 1,
		quiet  => 1,
	}),
	{
		access => [
			{
				id    => '23456',
				foo   => 'baz',
				phase => 'access',
			}
		],
		header_filter => [],
		body_filter   => [],
	},
	'multiple chains with a failing chain are translated'
);

done_testing;
