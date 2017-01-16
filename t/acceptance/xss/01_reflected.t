use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 7 * blocks() - 6;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Show the design of the resource
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
You've entered the following: 'bar'
--- no_error_log
[error]

=== TEST 2: Benign request is not caught in SIMULATE mode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			lua_resty_waf = require "resty.waf"
			local waf      = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
You've entered the following: 'bar'
--- no_error_log
"id":42043
"id":42059
"id":42069
"id":42076
"id":42083
"id":99001

=== TEST 3: Benign request is not caught in ACTIVE mode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			lua_resty_waf = require "resty.waf"
			local waf      = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
You've entered the following: 'bar'
--- no_error_log
"id":42043
"id":42059
"id":42069
"id":42076
"id":42083
"id":99001

=== TEST 4: Malicious request exploits reflected XSS vulnerability
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 200
--- response_body
You've entered the following: '<script>alert(1)</script>'
--- no_error_log
[error]

=== TEST 5: Malicious request is logged in SIMULATE mode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			lua_resty_waf = require "resty.waf"
			local waf      = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 200
--- response_body
You've entered the following: '<script>alert(1)</script>'
--- error_log
"id":42043
"id":42059
"id":42069
"id":42076
"id":42083
"id":99001
--- no_error_log
[error]

=== TEST 6: Malicious request is blocked in ACTIVE mode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			lua_resty_waf = require "resty.waf"
			local waf      = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()

			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 403
--- response_body_unlike
You've entered the following: '<script>alert\(1\)</script>'
--- error_log
"id":42043
"id":42059
"id":42069
"id":42076
"id":42083
"id":99001
--- no_error_log
[error]

