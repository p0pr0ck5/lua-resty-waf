use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: No dynamic value syntax
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "foo"
			local coll   = {}
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
--- no_error_log
[error]

=== TEST 2: Parse REMOTE_ADDR
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{REMOTE_ADDR}"
			local coll   = { REMOTE_ADDR = ngx.var.remote_addr }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1
--- no_error_log
[error]

=== TEST 3: Parse URI
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{URI}"
			local coll   = { URI = ngx.var.uri }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
/t
--- no_error_log
[error]

=== TEST 4: Parse SCORE
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{SCORE}"
			local coll   = { SCORE = 5 }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
5
--- no_error_log
[error]

=== TEST 5: Parse SCORE_THRESHOLD
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{SCORE_THRESHOLD}"
			local coll   = { SCORE_THRESHOLD = 10 }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
10
--- no_error_log
[error]

=== TEST 6: Parse URI_ARGS
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{URI_ARGS}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args() }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
URI_ARGS
--- no_error_log
[error]

=== TEST 7: Parse URI_ARGS (specific)
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{URI_ARGS.foo}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args() }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 8: Parse URI_ARGS (specific, dne)
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{URI_ARGS.foo}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args() }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo2=bar
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 9: Parse multiple string values
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{REMOTE_ADDR} - %{REQUEST_LINE}"
			local coll   = { REMOTE_ADDR = ngx.var.remote_addr, REQUEST_LINE = ngx.var.request }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1 - GET /t HTTP/1.1
--- no_error_log
[error]

=== TEST 10: Parse string and table values (1/2)
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{URI_ARGS.foo} - %{REQUEST_LINE}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args(), REQUEST_LINE = ngx.var.request }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
bar - GET /t?foo=bar HTTP/1.1
--- no_error_log
[error]

=== TEST 11: Parse string and table values (2/2)
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{REQUEST_LINE} - %{URI_ARGS.foo}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args(), REQUEST_LINE = ngx.var.request }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
GET /t?foo=bar HTTP/1.1 - bar
--- no_error_log
[error]

=== TEST 12: Parse invalid collections key
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{REMOTE_ADDRP}"
			local coll   = { REMOTE_ADDR = "127.0.0.1" }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log
[error]
Bad dynamic parse, no collection key REMOTE_ADDRP

=== TEST 13: Parse single lowercase key
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{remote_addr}"
			local coll   = { REMOTE_ADDR = ngx.var.remote_addr }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1
--- no_error_log
[error]

=== TEST 14: Parse multiple string values as lowercase key
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{remote_addr} - %{request_line}"
			local coll   = { REMOTE_ADDR = ngx.var.remote_addr, REQUEST_LINE = ngx.var.request }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1 - GET /t HTTP/1.1
--- no_error_log
[error]

=== TEST 15: Parse specific table value as lowercase key
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{uri_args.foo}"
			local coll   = { URI_ARGS = ngx.req.get_uri_args() }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

