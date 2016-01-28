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

=== TEST 2: Parse IP
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{IP}"
			local coll   = { IP = ngx.var.remote_addr }
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

=== TEST 6: Parse invalid collections key
--- config
	location /t {
		content_by_lua '
			local util   = require "lib.util"
			local key    = "%{IPP}"
			local coll   = { IP = "127.0.0.1" }
			local parsed = util.parse_dynamic_value({ _pcre_flags = "" }, key, coll)
			ngx.say(parsed)
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log
[error]
Bad dynamic parse, no collection key IPP

