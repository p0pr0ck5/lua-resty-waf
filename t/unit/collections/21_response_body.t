use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: RESPONSE_BODY collections variable (valid type, one chunk)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		body_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()

			local collections = ngx.ctx.collections
			ngx.log(ngx.INFO, [["]] .. tostring(collections.RESPONSE_BODY) .. [["]])
		';

	}
--- request
GET /t
--- user_files
>>> t
Hello, world!
--- error_code: 200
--- response_body
Hello, world!
--- error_log eval
["Hello, world!
"]
--- no_error_log
[error]

=== TEST 2: RESPONSE_BODY collections variable (valid type, multiple chunks)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua '
			ngx.header["Content-Type"] = "text/plain"
			ngx.header["Content-Length"] = 14
			ngx.say("Hello,")
			ngx.say("world!")
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		body_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()

			local collections = ngx.ctx.collections
			ngx.log(ngx.INFO, tostring(collections.RESPONSE_BODY))
		';

	}
--- request
GET /t
--- user_files
>>> t
Hello, world!
--- error_code: 200
--- response_body
Hello,
world!
--- error_log eval
["Hello,\n", qr/^world!\n/]
--- no_error_log
[error]

=== TEST 3: RESPONSE_BODY collections variable (invalid type, one chunk)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		header_filter_by_lua '
			ngx.header["Content-Type"] = "text/foo"

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		body_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()

			local collections = ngx.ctx.collections
			ngx.log(ngx.INFO, [["]] .. tostring(collections.RESPONSE_BODY) .. [["]])
		';

	}
--- request
GET /t
--- user_files
>>> t
Hello, world!
--- error_code: 200
--- response_body
Hello, world!
--- no_error_log eval
["Hello, world!
"]
--- no_error_log
[error]

=== TEST 4: RESPONSE_BODY collections variable type (valid type, one chunk)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		header_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		body_filter_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()

			local collections = ngx.ctx.collections
			ngx.log(ngx.INFO, [["]] .. type(collections.RESPONSE_BODY) .. [["]])
		';

	}
--- request
GET /t
--- user_files
>>> t
Hello, world!
--- error_code: 200
--- response_body
Hello, world!
--- error_log
"string"
--- no_error_log
[error]

