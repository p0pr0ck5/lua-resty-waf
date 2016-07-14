use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: SCORE collections variable
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.SCORE())
		';
	}
--- request
GET /t
--- more_headers
Accept: */*
User-Agent: lua-resty-waf Dummy
--- error_code: 200
--- response_body
3
--- no_error_log
[error]

=== TEST 2: SCORE collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.SCORE))
		';
	}
--- request
GET /t
--- more_headers
Accept: */*
User-Agent: lua_resty_waf Dummy
--- error_code: 200
--- response_body
function
--- no_error_log
[error]

=== TEST 3: SCORE collections variable (return type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.SCORE()))
		';
	}
--- request
GET /t
--- more_headers
Accept: */*
User-Agent: lua_resty_waf Dummy
--- error_code: 200
--- response_body
number
--- no_error_log
[error]

