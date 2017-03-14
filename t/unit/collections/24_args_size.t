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

=== TEST 1: ARGS_COMBINED_SIZE collections variable (no args)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.ARGS_COMBINED_SIZE)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
0
--- no_error_log
[error]

=== TEST 2: ARGS_COMBINED_SIZE collections variable (GET args)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.ARGS_COMBINED_SIZE)
		}
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
7
--- no_error_log
[error]

=== TEST 3: ARGS_COMBINED_SIZE collections variable (POST args)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.ARGS_COMBINED_SIZE)
		}
	}
--- request
POST /t
foo=bar&baz=bat
--- error_code: 200
--- response_body
15
--- no_error_log
[error]

=== TEST 4: ARGS_COMBINED_SIZE collections variable (GET args)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(collections.ARGS_COMBINED_SIZE)
		}
	}
--- request
POST /t?foo=bar
foo=bar&baz=bat
--- error_code: 200
--- response_body
22
--- no_error_log
[error]

=== TEST 5: ARGS_COMBINED_SIZE collections variable (type verification)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			ngx.say(type(collections.ARGS_COMBINED_SIZE))
		}
	}
--- request
POST /t?foo=bar
foo=bar&baz=bat
--- error_code: 200
--- response_body
number
--- no_error_log
[error]

