use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_HEADER_NAMES collections variable (single element)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.say(util.table_has_value("x-foo", collections.REQUEST_HEADER_NAMES))
		';
	}
--- request
GET /t
--- more_headers
X-Foo: bar
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 2: REQUEST_HEADER_NAMES collections variable (multiple elements)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.say(util.table_has_value("x-foo", collections.REQUEST_HEADER_NAMES))
		';
	}
--- request
GET /t
--- more_headers
X-Foo: bar
X-Foo: baz
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: REQUEST_HEADER_NAMES collections variable (non-existent element)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.say(util.table_has_value("x-foo", collections.REQUEST_HEADER_NAMES))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: REQUEST_HEADER_NAMES collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local util = require "lib.util"

			ngx.say(type(collections.REQUEST_HEADER_NAMES))
		';
	}
--- request
GET /t
--- more_headers
X-Foo: bar
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

