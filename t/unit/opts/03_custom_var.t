use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Set a static var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_var("foo", "bar")
			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.collections.TX.foo)
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: Set a dynamic var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_var("foo", "%{REMOTE_ADDR}")
			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.collections.TX.foo)
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1
--- no_error_log
[error]

=== TEST 3: Set a dynamic var with a specific element
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_var("foo", "%{REQUEST_HEADERS.X-Foo}")
			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.collections.TX.foo)
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- more_headers
X-Foo: bar
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

