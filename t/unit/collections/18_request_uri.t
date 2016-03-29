use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_URI collections variable (empty)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_URI)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
/t
--- no_error_log
[error]

=== TEST 2: REQUEST_URI collections variable (single pair)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_URI)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
/t?foo=bar
--- no_error_log
[error]

=== TEST 3: REQUEST_URI collections variable (complex)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_URI)
		';
	}
--- request
GET /t?foo=bar&foo=bat&frob&qux=
--- error_code: 200
--- response_body
/t?foo=bar&foo=bat&frob&qux=
--- no_error_log
[error]

=== TEST 4: REQUEST_URI collections variable (type verification, empty)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_URI))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

=== TEST 5: REQUEST_URI collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_URI))
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

