use Test::More;
use Test::Exception;
use Test::MockModule;

use lib 'tools';
use Modsec2LRW qw(parse_tokens);

my $Mock = Test::MockModule->new('Modsec2LRW');

$Mock->mock(parse_vars => sub {
	my ($arg) = @_;
	return "$arg-mocked";
});

$Mock->mock(parse_operator => sub {
	my ($operator) = @_;
	return "$operator-mocked";
});

$Mock->mock(parse_actions => sub {
	my ($actions) = @_;
	return "$actions-mocked";
});

my $secrule   = 'SecRule';
my $secaction = 'SecAction';
my $args      = 'ARGS';
my $operator  = 'foo';
my $actions   = 'block,id:12345,msg:\'hello world\'';
my $parsed;

lives_ok(
	sub { parse_tokens($secrule, $args, $operator, $actions) },
	'lives with SecRule and four tokens'
);

lives_ok(
	sub { parse_tokens($secaction, $actions) },
	'lives with SecAction and two tokens'
);

dies_ok(
	sub { parse_tokens($secaction, $args, $operator, $actions) },
	'dies with SecAction and four tokens'
);

$parsed = parse_tokens($secrule, $args, $operator, $actions);
is(
	$parsed->{original},
	'SecRule ARGS foo block,id:12345,msg:\'hello world\'',
	'tokens are rejoined by space'
);

is(
	$parsed->{directive},
	'SecRule',
	'directive token is returned directly to the directive key'
);

is(
	$parsed->{vars},
	'ARGS-mocked',
	'vars key is built from vars token'
);

is(
	$parsed->{operator},
	'foo-mocked',
	'operator key is built from operator token'
);

is(
	$parsed->{actions},
	'block,id:12345,msg:\'hello world\'-mocked',
	'actions key is built from actions token'
);

$parsed = parse_tokens($secaction, $actions);
is(
	$parsed->{original},
	'SecAction block,id:12345,msg:\'hello world\'',
	'tokens are rejoined by space'
);

is(
	$parsed->{directive},
	'SecAction',
	'directive token is returned directly to the directive key'
);

is(
	$parsed->{vars},
	undef,
	'vars key is undef when directive is not SecRule'
);

is(
	$parsed->{operator},
	undef,
	'operator key is undef when directive is not SecRule'
);

is(
	$parsed->{actions},
	'block,id:12345,msg:\'hello world\'-mocked',
	'actions key is built from actions token'
);

done_testing;
