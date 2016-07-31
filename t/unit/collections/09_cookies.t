use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: COOKIES collections variable (single element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.COOKIES["x-foo"])
		';
	}
--- request
GET /t
--- more_headers
Cookie: x-foo=bar
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: COOKIES collections variable (multiple elements)
# n.b. resty.cookie will only override a cookie sent multiple times
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.COOKIES["x-foo"])
		';
	}
--- request
GET /t
--- more_headers
Cookie: x-foo=bar; x-foo=baz
--- error_code: 200
--- response_body
baz
--- no_error_log
[error]

=== TEST 3: COOKIES collections variable (non-existent element)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.COOKIES["x-foo"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 4: COOKIES collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.COOKIES))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

