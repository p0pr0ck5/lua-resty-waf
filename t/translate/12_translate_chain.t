use Test::More;
use Test::MockModule;

use lib 'tools';
use Modsec2LRW qw(translate_chain);

my $Mock = Test::MockModule->new('Modsec2LRW');

$Mock->mock(translate_vars => sub {
	my ($rule, $translation, $force) = @_;

	push @{$translation->{vars}}, $_ for @{$rule->{vars}};
});

$Mock->mock(translate_operator => sub {
	my ($rule, $translation, $path) = @_;

	$translation->{operator} = $rule->{operator};
});

$Mock->mock(translate_actions => sub {
	my ($rule, $translation, $silent) = @_;

	$translation->{$_->{action}} = $_->{value} for @{$rule->{actions}};
});

my @out;

@out = translate_chain({
	chain => [
		{
			actions   => [
				{ action => 'action', value => 'DENY',  },
				{ action => 'id'    , value => 12345,   },
				{ action => 'phase' , value => 'access' },
			],
			directive => 'SecRule',
			operator  => '@rx',
			vars      => [
				{ baz => 'bat', },
			],
		}
	],
});
is_deeply(
	\@out,
	[
		{
			action    => 'DENY',
			id        => 12345,
			phase     => 'access',
			operator  => '@rx',
			vars      => [
				{ baz => 'bat', },
			],
		}
	],
	'a single rule with a SecRule is translated'
);

@out = translate_chain({
	chain => [
		{
			actions   => [
				{ action => 'action', value => 'DENY',  },
				{ action => 'id'    , value => 12345,   },
				{ action => 'phase' , value => 'access' },
			],
			directive => 'SecAction',
		}
	],
});
is_deeply(
	\@out,
	[
		{
			action    => 'DENY',
			id        => 12345,
			phase     => 'access',
			vars      => [
				{ unconditional => 1, },
			],
		}
	],
	'a single rule with SecAction is translated'
);

@out = translate_chain({
	chain => [
		{
			actions   => [
				{ action => 'mark' },
			],
			directive => 'SecMarker',
		}
	],
});
is_deeply(
	\@out,
	[
		{
			action     => 'DENY',
			id         => 'mark',
			op_negated => 1,
			vars       => [
				{ 
					unconditional => 1,
				},
			],
		}
	],
	'a single rule with SecAction is translated'
);

@out = translate_chain({
	chain => [
		{
			actions   => [
				{ action => 'action', value => 'DENY',  },
				{ action => 'id'    , value => 12345,   },
				{ action => 'phase' , value => 'access' },
			],
			directive => 'SecRule',
			operator  => '@rx',
			vars      => [
				{ foo => 'bar', },
			],
		},
		{
			actions   => [
				{ action => 'phase', value => 'access', },
			],
			directive => 'SecRule',
			operator  => '@rx',
			vars      => [
				{ baz => 'bat', },
			],
		},
	],
});
is_deeply(
	\@out,
	[
		{
			action    => 'CHAIN',
			id        => 12345,
			phase     => 'access',
			operator  => '@rx',
			vars      => [
				{ foo => 'bar', },
			],
		},
		{
			action    => 'DENY',
			id        => 12345,
			phase     => 'access',
			operator  => '@rx',
			vars      => [
				{ baz => 'bat', },
			],
		}
	],
	'two rules with SecRule are translated'
);

@out = translate_chain({
	chain => [
		{
			actions   => [
				{ action => 'action', value => 'DENY',  },
				{ action => 'id'    , value => 12345,   },
				{ action => 'phase' , value => 'access' },
				{ action => 'skip'  , value => 1,       },
			],
			directive => 'SecRule',
			operator  => '@rx',
			vars      => [
				{ foo => 'bar', },
			],
		},
		{
			actions   => [
				{ action => 'phase', value => 'access', },
			],
			directive => 'SecRule',
			operator  => '@rx',
			vars      => [
				{ baz => 'bat', },
			],
		},
	],
});
is_deeply(
	\@out,
	[
		{
			action    => 'CHAIN',
			id        => 12345,
			phase     => 'access',
			operator  => '@rx',
			vars      => [
				{ foo => 'bar', },
			],
		},
		{
			action    => 'DENY',
			id        => 12345,
			phase     => 'access',
			operator  => '@rx',
			skip      => 1,
			vars      => [
				{ baz => 'bat', },
			],
		}
	],
	'skip directive is moved to the chain end'
);

done_testing;
