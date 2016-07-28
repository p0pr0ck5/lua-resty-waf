use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: trim
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "  hello world   "
			local transform = lookup.transform["trim"]({}, value)
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

=== TEST 2: trim (no change)
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "hello world"
			local transform = lookup.transform["trim"]({}, value)
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

=== TEST 3: trim_left
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "  hello world"
			local transform = lookup.transform["trim_left"]({}, value)
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

=== TEST 4: trim_left (right whitespace untrimmed)
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "  hello world   "
			local transform = lookup.transform["trim_left"]({}, value)
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

=== TEST 5: trim_right
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "hello world   "
			local transform = lookup.transform["trim_right"]({}, value)
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

=== TEST 6: trim_right (left whitespace untrimmed)
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "  hello world   "
			local transform = lookup.transform["trim_right"]({}, value)
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

