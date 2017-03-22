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

=== TEST 1: TX collection is populated with the correct number of elements
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local crs_options = require("resty.waf.options").crs_config
			local tx = ngx.ctx.lua_resty_waf.collections.TX

			local cnt = 0

			for k, v in pairs(tx) do
				cnt = cnt + 1
			end

			ngx.say(cnt)
		}
	}
--- more_headers
Accept: */*
User-Agent: test::nginx::socket
--- request
GET /t
--- error_code: 200
--- response_body
24
--- no_error_log
[error]

=== TEST 2: Overwrite a default CRS config in the TX collection
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_var("PARANOIA_LEVEL", 2)
			waf:exec()
		}

		content_by_lua_block {
			local crs_options = require("resty.waf.options").crs_config
			local tx = ngx.ctx.lua_resty_waf.collections.TX

			ngx.say(tx.PARANOIA_LEVEL)
		}
	}
--- more_headers
Accept: */*
User-Agent: test::nginx::socket
--- request
GET /t
--- error_code: 200
--- response_body
2
--- no_error_log
[error]

