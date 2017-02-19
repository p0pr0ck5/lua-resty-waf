use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Bail of out request due to if
--- http_config eval: $::HttpConfig
--- config
	location /t {
		if ($uri ~ t) {
			return 403;
		}

		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- error_code: 403
--- error_log
Not attempting to write log as lua-resty-waf was never exec'd
--- no_error_log
[error]
nil was given to table_keys

=== TEST 2: Do not bail of out request due to if
--- http_config eval: $::HttpConfig
--- config
	location /t {
		if ($uri ~ s) {
			return 403;
		}

		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
nil was given to table_keys
Not attempting to write log as lua-resty-waf was never exec'd
