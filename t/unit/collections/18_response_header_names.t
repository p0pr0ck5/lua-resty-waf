use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: RESPONSE_HEADER_NAMES collections variable (single element)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			ngx.header["X-Foo"] = "bar"
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.log(ngx.INFO, [["]] .. tostring(util.table_has_value("x-foo", collections.RESPONSE_HEADER_NAMES)) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"true" while logging request
--- no_error_log
[error]

=== TEST 2: RESPONSE_HEADER_NAMES collections variable (multiple elements)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			ngx.header["X-Foo"] = { "bar", "baz" }
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.log(ngx.INFO, [["]] .. tostring(util.table_has_value("x-foo", collections.RESPONSE_HEADER_NAMES)) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"true" while logging request
--- no_error_log
[error]

=== TEST 3: RESPONSE_HEADER_NAMES collections variable (non-existent element)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections
			local util        = require "lib.util"

			ngx.log(ngx.INFO, [["]] .. tostring(util.table_has_value("x-foo", collections.RESPONSE_HEADER_NAMES)) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"false" while logging request
--- no_error_log
[error]

=== TEST 4: RESPONSE_HEADER_NAMES collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. type(collections.RESPONSE_HEADER_NAMES) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"table" while logging request
--- no_error_log
[error]
