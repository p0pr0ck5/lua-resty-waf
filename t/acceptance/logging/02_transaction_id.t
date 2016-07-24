use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Transaction ID exists in log file
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/log[(][)]: \[[a-f0-9]{20}\]/
--- no_error_log
[error]

=== TEST 2: Transaction ID exists as request header
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("req_tid_header", true)
			waf:exec()
		';

		content_by_lua '
			local t = ngx.req.get_headers()
			ngx.say("X-lua_resty_waf-ID: " .. t["X-Lua-Resty-WAF-ID"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body_like
^X-lua_resty_waf-ID: [a-f0-9]{20}$
--- no_error_log
[error]

=== TEST 3: Transaction ID exists as response header
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("res_tid_header", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- response_headers_like
X-lua_resty_waf-ID: [a-f0-9]{20}
--- no_error_log
[error]

