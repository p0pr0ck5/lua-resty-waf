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

=== TEST 1: REQUEST_URI_RAW collections variable (empty)
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

			ngx.say(collections.REQUEST_URI_RAW)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
/t
--- no_error_log
[error]

=== TEST 2: REQUEST_URI_RAW collections variable (single pair)
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

			ngx.say(collections.REQUEST_URI_RAW)
		}
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
/t?foo=bar
--- no_error_log
[error]

=== TEST 3: REQUEST_URI_RAW collections variable (contains domain)
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

			ngx.say(collections.REQUEST_URI_RAW)
		}
	}
--- request
GET http://localhost/t?foo=bar&foo=bat&frob&qux=
--- error_code: 200
--- response_body
http://localhost/t?foo=bar&foo=bat&frob&qux=
--- no_error_log
[error]

=== TEST 4: REQUEST_URI_RAW collections variable (type verification, empty)
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

			ngx.say(type(collections.REQUEST_URI_RAW))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

=== TEST 5: REQUEST_URI_RAW collections variable (type verification)
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

			ngx.say(type(collections.REQUEST_URI_RAW))
		}
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

