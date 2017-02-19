use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 2 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Default threshold doesn't deny benign request
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- more_headers
Accept: */*
User-Agent: testy mctesterson
--- request
GET /t?foo=bar
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Lowered threshold denies dummy request
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("score_threshold", 3)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- more_headers
Accept: */*
User-Agent: lua-resty-waf Dummy
--- request
GET /t?foo=bar
--- error_code: 403
--- no_error_log
[error]

=== TEST 3: Default threshold denies suspicious request
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- more_headers
User-Agent: nessus
--- request
GET /t?foo=bar
--- error_code: 403
--- no_error_log
[error]

=== TEST 4: Raised threshold does not deny suspicious request
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("score_threshold", 20)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- more_headers
User-Agent: nessus
--- request
GET /t?foo=bar
--- error_code: 200
--- no_error_log
[error]

