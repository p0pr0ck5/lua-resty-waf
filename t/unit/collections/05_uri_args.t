use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: URI_ARGS collections variable (single element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.URI_ARGS["foo"])
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: URI_ARGS collections variable (multiple elements)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.URI_ARGS["foo"])
		';
	}
--- request
GET /t?foo=bar&foo=baz
--- error_code: 200
--- response_body
barbaz
--- no_error_log
[error]

=== TEST 3: URI_ARGS collections variable (non-existent element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.URI_ARGS["foo"])
		';
	}
--- request
GET /t?frob=qux
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 4: URI_ARGS collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.URI_ARGS))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

