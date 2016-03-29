use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: RESPONSE_HEADERS collections variable (single element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			ngx.header["X-Foo"] = "bar"
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. collections.RESPONSE_HEADERS["X-Foo"] .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"bar" while logging request
--- no_error_log
[error]

=== TEST 2: RESPONSE_HEADERS collections variable (multiple elements)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			ngx.header["X-Foo"] = { "bar", "baz" }
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			for k, v in ipairs(collections.RESPONSE_HEADERS["X-Foo"]) do
				ngx.log(ngx.INFO, [["]] .. v .. [["]])
			end
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"bar" while logging request
"baz" while logging request
--- no_error_log
[error]

=== TEST 3: RESPONSE_HEADERS collections variable (non-existent element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. tostring(collections.RESPONSE_HEADERS["X-Foo"]) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"nil" while logging request
--- no_error_log
[error]

=== TEST 4: RESPONSE_HEADERS collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			ngx.exit(ngx.HTTP_OK)
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. type(collections.RESPONSE_HEADERS) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"table" while logging request
--- no_error_log
[error]
