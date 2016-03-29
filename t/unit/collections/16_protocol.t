use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: PROTOCOL collections variable
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.PROTOCOL)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
HTTP/1.1
--- no_error_log
[error]

=== TEST 2: PROTOCOL collections variable (HTTP/1.0)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.PROTOCOL)
		';
	}
--- request
GET /t HTTP/1.0
--- error_code: 200
--- response_body
HTTP/1.0
--- no_error_log
[error]

=== TEST 3: PROTOCOL collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.PROTOCOL))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

