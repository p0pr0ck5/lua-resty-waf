use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_ARGS collections variable (single element)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.REQUEST_ARGS["foo"])
		';
	}
--- request
POST /t?foo=bar
bat=baz
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: REQUEST_ARGS collections variable (multiple elements)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.REQUEST_ARGS["foo"])
		';
	}
--- request
POST /t?foo=bar
foo=baz
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
barbaz
--- no_error_log
[error]

=== TEST 3: REQUEST_ARGS collections variable (non-existent element)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.REQUEST_ARGS["foo"])
		';
	}
--- request
POST /t?frob=qux
bat=baz
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 4: REQUEST_ARGS collections variable (type verification)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(type(collections.REQUEST_ARGS))
		';
	}
--- request
GET /t
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

