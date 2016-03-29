use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: GET request with no arguments is ignored
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Match of rule 11002
--- no_error_log
[error]

=== TEST 2: GET request with URI args is not ignored
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?a=b
--- error_code: 200
--- no_error_log
[error]
Match of rule 11002

=== TEST 3: HEAD request with no arguments is ignored
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
HEAD /t
--- error_code: 200
--- error_log
Match of rule 11002
--- no_error_log
[error]

=== TEST 4: HEAD request with URI args is not ignored
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
HEAD /t?a=b
--- error_code: 200
--- no_error_log
[error]
Match of rule 11002

=== TEST 5: POST request is not ignored
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request
POST /t
foo=bar
--- error_code: 200
--- no_error_log
[error]
Match of rule 11002

