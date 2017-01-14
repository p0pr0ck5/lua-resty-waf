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

=== TEST 1: METHOD collections variable (GET)
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

			ngx.say(collections.METHOD)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
GET
--- no_error_log
[error]

=== TEST 2: METHOD collections variable (POST)
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

			ngx.say(collections.METHOD)
		';
	}
--- request
POST /t
--- error_code: 200
--- response_body
POST
--- no_error_log
[error]

=== TEST 3: METHOD collections variable (HEAD)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()

			local collections = ngx.ctx.lua_resty_waf.collections
			ngx.header["X-Method"] = collections.METHOD
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
HEAD /t
--- error_code: 200
--- response_headers
X-Method: HEAD
--- no_error_log
[error]

=== TEST 4: METHOD collections variable (type verification)
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

			ngx.say(type(collections.METHOD))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

