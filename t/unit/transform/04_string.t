use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: lowercase
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "HELLO WORLD"
			local transform = lookup.transform["lowercase"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

