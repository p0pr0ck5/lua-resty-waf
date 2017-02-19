use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Execute user-defined phase (collections available)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				phase = "access"
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
access
/t
--- no_error_log
[error]

=== TEST 2: Execute user-defined phase (some collections not available)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				phase = "header_filter"
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf
			ngx.say(ctx.phase)
			ngx.say(ctx.collections.STATUS)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
header_filter
0
--- no_error_log
[error]

=== TEST 3: Execute user-defined phase (API disabled in collections lookup)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				phase = "body_filter"
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf
			ngx.say(ctx.phase)
			ngx.say(ctx.collections.STATUS)
		}
	}
--- request
GET /t
--- error_code: 500
--- error_log
API disabled
