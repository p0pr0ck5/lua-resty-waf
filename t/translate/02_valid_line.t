use Test::More;

use lib 'tools';
use Modsec2LRW qw(valid_line);

is(
	valid_line('SecRule '),
	1,
	'line starting with SecRule is valid'
);

is(
	valid_line('SecAction '),
	1,
	'line starting with SecAction is valid'
);

is(
	valid_line('SecDefaultAction '),
	1,
	'line starting with SecDefaultAction is valid'
);

is(
	valid_line('SecMarker '),
	1,
	'line starting with SecMarker is valid'
);

is(
	valid_line('SecFoo '),
	'',
	'line starting with unknown directive is invalid'
);

is(
	valid_line(sprintf "%08X\n", rand(0xffffffff)),
	'',
	'line starting with random junk is invalid'
);

done_testing;
