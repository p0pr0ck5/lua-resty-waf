use Test::More;

use lib 'tools';
use Modsec2LRW qw(translate_macro);

is(
	translate_macro('foo'),
	'foo',
	'translate a string without a marker'
);

is(
	translate_macro('%{foo}'),
	'%{foo}',
	'translate a string wrapped in a marker'
);

is(
	translate_macro('%{REQUEST_METHOD}'),
	'%{METHOD}',
	'translating a valid replacement'
);

is(
	translate_macro('REQUEST_METHOD'),
	'REQUEST_METHOD',
	'translate an unmarked valid replacement'
);

is(
	translate_macro('%{ARGS.foo}'),
	'%{REQUEST_ARGS.foo}',
	'translate a replacement with a specific element'
);

is(
	translate_macro('%{RESPONSE_CONTENT_TYPE}'),
	'%{RESPONSE_HEADERS.Content-Type}',
	'translate a replacement with an implicit specific element'
);

is(
	translate_macro('%{REQUEST_METHOD} - %{RESPONSE_STATUS}'),
	'%{METHOD} - %{STATUS}',
	'translating two valid replacements'
);

is(
	translate_macro('%{REQUEST_METHOD} - %{foo}'),
	'%{METHOD} - %{foo}',
	'translating one valid and one invalid replacement'
);

is(
	translate_macro('%{ARGS.foo} - %{RESPONSE_STATUS}'),
	'%{REQUEST_ARGS.foo} - %{STATUS}',
	'translating two valid replacements, one with a specific element'
);

is(
	translate_macro('%{RESPONSE_CONTENT_TYPE} - %{RESPONSE_STATUS}'),
	'%{RESPONSE_HEADERS.Content-Type} - %{STATUS}',
	'translating two valid replacements, one with an implicit specific element'
);

is(
	translate_macro('{foo}'),
	'{foo}',
	'translate a string with a malformed marker (1/3)'
);

is(
	translate_macro('%{foo'),
	'%{foo',
	'translate a string with a malformed marker (2/3)'
);

is(
	translate_macro('%{foo { bar }'),
	'%{foo { bar }',
	'translate a string with a malformed marker (3/3)'
);


done_testing;
