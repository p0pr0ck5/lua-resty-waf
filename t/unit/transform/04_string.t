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

=== TEST 2: string length
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "hello world"
			local transform = lookup.transform["length"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
11
--- no_error_log
[error]

=== TEST 3: string length (number)
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = 8001
			local transform = lookup.transform["length"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
4
--- no_error_log
[error]

=== TEST 4: string length (boolean)
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = true
			local transform = lookup.transform["length"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
4
--- no_error_log
[error]

