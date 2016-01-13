use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Existing value (string)
--- config
	location /t {
		content_by_lua '
			local util = require "lib.util"
			local t    = { foo = "bar", qux = "frob" }
			local val  = util.table_has_value({}, "frob", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 2: Existing value (integer)
--- config
	location /t {
		content_by_lua '
			local util = require "lib.util"
			local t    = { 4, 10, 7.2, 1, 99, "foo", "bar" }
			local val  = util.table_has_value({}, 1, t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: Non existing value (string)
--- config
	location /t {
		content_by_lua '
			local util = require "lib.util"
			local t    = { foo = "bar", qux = "frob" }
			local val  = util.table_has_value({}, "baz", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: Non existing value (integer)
--- config
	location /t {
		content_by_lua '
			local util = require "lib.util"
			local t    = { 4, 10, 7.2, 1, 99, "foo", "bar" }
			local val  = util.table_has_value({}, 0, t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 5: Haystack is not a table
--- config
	location /t {
		content_by_lua '
			local util = require "lib.util"
			local t    = "foo, bar"
			local val  = util.table_has_value({}, "foo", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log
fatal_fail
Cannot search for a needle when haystack is type string
