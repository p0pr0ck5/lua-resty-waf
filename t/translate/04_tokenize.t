use Test::More;

use lib 'tools';
use Modsec2LRW qw(tokenize);

my @out;

@out = tokenize('foo');
is_deeply(
	\@out,
	[ qw(foo) ],
	'single token'
);

@out = tokenize('foo bar');
is_deeply(
	\@out,
	[ qw(foo bar) ],
	'two tokens'
);

@out = tokenize('"foo"');
is_deeply(
	\@out,
	[ qw(foo) ],
	'quote-wrapped token'
);

@out = tokenize('"foo" "bar"');
is_deeply(
	\@out,
	[ qw(foo bar) ],
	'two quote-wrapped tokens'
);

@out = tokenize('"foo" bar');
is_deeply(
	\@out,
	[ qw(foo bar) ],
	'two tokens, first quote-wrapped'
);

@out = tokenize('foo "bar"');
is_deeply(
	\@out,
	[ qw(foo bar) ],
	'two tokens, second quote-wrapped'
);

@out = tokenize('"foo \"bar"');
is_deeply(
	\@out,
	[ q(foo "bar) ],
	'quote-wrapped token with single escaped quote'
);

@out = tokenize('"foo \"bar\""');
is_deeply(
	\@out,
	[ q(foo "bar") ],
	'quote-wrapped token with two escaped quotes'
);

@out = tokenize('"foo \"" bar');
is_deeply(
	\@out,
	[ q(foo "), q(bar) ],
	'quote-wrapped token with escaped quote, then unquoted token'
);

@out = tokenize('foo "bar \""');
is_deeply(
	\@out,
	[ q(foo), q(bar ") ],
	'unquoted token, then quote-wrapped token with escaped token'
);

@out = tokenize('foo bar baz "bat"');
is_deeply(
	\@out,
	[ qw(foo bar baz bat) ],
	'four tokens, last is quote-wrapped'
);

@out = tokenize('foo bar baz "bat,qux:\'frob foo\'"');
is_deeply(
	\@out,
	[ qw(foo bar baz), q(bat,qux:'frob foo') ],
	'four tokens, last is with escaped single quotes'
);

@out = tokenize('foo bar "baz qux" "bat"');
is_deeply(
	\@out,
	[ qw(foo bar), q(baz qux), q(bat) ],
	'four tokens, two are quote-wrapped'
);

@out = tokenize('foo bar "baz \"qux\"" "bat"');
is_deeply(
	\@out,
	[ qw(foo bar), q(baz "qux"), q(bat) ],
	'four tokens, two are quote-wrapped, one escaped quote'
);

done_testing;
