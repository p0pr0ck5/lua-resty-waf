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

=== TEST 1: URI collections variable
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

			ngx.say(collections.URI)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
/t
--- no_error_log
[error]

=== TEST 2: URI collections variable (longer URI)
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

			ngx.say("Hello world!")
		';
	}

	location /foo/bar {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.URI)
		';
	}
--- request
GET /foo/bar/
--- error_code: 200
--- response_body
/foo/bar/
--- no_error_log
[error]

=== TEST 3: URI collections variable (type verification)
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

			ngx.say(type(collections.URI))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

