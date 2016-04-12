use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 2 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Default deny status (403)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- no_error_log
[error]

=== TEST 2: Alternative deny status (status constant)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("deny_status", ngx.HTTP_NOT_FOUND)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 404
--- no_error_log
[error]

=== TEST 2: Alternative deny status (integer)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("deny_status", 418)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 418
--- no_error_log
[error]
