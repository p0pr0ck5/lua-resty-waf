use Test::More;
use Test::Exception;
use Test::MockModule;

use Cwd qw(cwd);
my $pwd = cwd();

use lib 'tools';
use Modsec2LRW qw(translate_operator);

my $Mock = Test::MockModule->new('Modsec2LRW');

$Mock->mock(translate_macro => sub {
	my ($pattern) = @_;

	return "$pattern";
});

my $translation;

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'rx',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'REGEX',
		pattern  => 'foo',
	},
	'translate an operator'
);

dies_ok(
	sub {
		translate_operator(
			{
				operator => {
					operator => 'x',
					pattern  => 'foo',
				},
			},
			$translation,
			undef
		);
	},
	'dies on invalid operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'containsWord',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'REGEX',
		pattern  => '\bfoo\b',
	},
	'translate an operator that modifies the pattern'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'rx',
			pattern  => 'foo',
			negated  => 1,
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator   => 'REGEX',
		pattern    => 'foo',
		op_negated => 1,
	},
	'translate an operator with the negated flag'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'gt',
			pattern  => '5',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'GREATER',
		pattern  => 5,
	},
	'caste a pattern that looks like an integer to a number'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'gt',
			pattern  => '.2',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'GREATER',
		pattern  => 0.2,
	},
	'caste a pattern that looks like a decimal to a number'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'pm',
			pattern  => 'foo bar baz bat',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'PM',
		pattern  => [ qw(foo bar baz bat) ],
	},
	'split the PM operator pattern'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'ipMatch',
			pattern  => '1.2.3.4,5.6.7.8,10.10.10.0/24',
		},
	},
	$translation,
	undef
);
is_deeply(
	$translation,
	{
		operator => 'CIDR_MATCH',
		pattern  => [ qw(1.2.3.4 5.6.7.8 10.10.10.0/24) ],
	},
	'split the ipMatch operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'beginsWith',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is(
	$translation->{actions}->{parsepattern},
	1,
	'auto expand the beginsWith operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'contains',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is(
	$translation->{actions}->{parsepattern},
	1,
	'auto expand the contains operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'endsWith',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is(
	$translation->{actions}->{parsepattern},
	1,
	'auto expand the endsWith operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'streq',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is(
	$translation->{actions}->{parsepattern},
	1,
	'auto expand the streq operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'within',
			pattern  => 'foo',
		},
	},
	$translation,
	undef
);
is(
	$translation->{actions}->{parsepattern},
	1,
	'auto expand the within operator'
);

$translation = {};
translate_operator(
	{
		operator => {
			operator => 'ipMatchFromFile',
			pattern  => 'ips.txt'
		}
	},
	$translation,
	"$pwd/t/data"
);
is_deeply(
	$translation,
	{
		operator => 'CIDR_MATCH',
		pattern  => [ qw(1.2.3.4 5.6.7.8 10.10.10.0/24) ],
	},
	'translation reads successfully from file'
);

dies_ok(
	sub {
		translate_operator(
			{
				operator => {
					operator => 'ipMatchFromFile',
					pattern  => 'ips.txt'
				}
			},
			$translation,
			"$pwd/t/dne"
		);
	},
	'dies on translating pattern file in invalid path (explicitly given)'
);

dies_ok(
	sub {
		translate_operator(
			{
				operator => {
					operator => 'ipMatchFromFile',
					pattern  => 'ips.txt'
				}
			},
			$translation,
			undef
		);
	},
	'dies on translating pattern file in invalid path (none given)'
);

done_testing;
