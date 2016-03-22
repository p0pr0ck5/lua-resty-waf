use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: sql_hex_decode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "0x48656c6c6f2c20776f726c6421"
			local transform = lookup.transform["sql_hex_decode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
Hello, world!
--- no_error_log
[error]

=== TEST 2: invalid sql_hex_decode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "48656c6c6f2c20776f726c6421"
			local transform = lookup.transform["sql_hex_decode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
48656c6c6f2c20776f726c6421
--- no_error_log
[error]

=== TEST 3: hex_decode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "48656c6c6f2c20776f726c6421"
			local transform = lookup.transform["hex_decode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
Hello, world!
--- no_error_log
[error]

=== TEST 4: hex_encode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "Hello, world!"
			local transform = lookup.transform["hex_encode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
48656c6c6f2c20776f726c6421
--- no_error_log
[error]

