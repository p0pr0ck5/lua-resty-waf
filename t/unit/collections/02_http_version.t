use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: HTTP_VERSION collections variable
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.HTTP_VERSION)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
1.1
--- no_error_log
[error]

=== TEST 2: HTTP_VERSION collections variable (HTTP/1.0)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.HTTP_VERSION)
		';
	}
--- request
GET /t HTTP/1.0
--- error_code: 200
--- response_body
1
--- no_error_log
[error]

=== TEST 3: HTTP_VERSION collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.HTTP_VERSION))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
number
--- no_error_log
[error]

