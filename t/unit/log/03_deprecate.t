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

=== TEST 1: Print a warning via deprecate
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.deprecate(waf, "We have logged a warning!")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/\[warn\].*DEPRECATED: We have logged a warning!/
--- no_error_log
[error]

=== TEST 2: Deprecate with a future fatal version
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local base = require "resty.waf.base"
			base.version = "0.1"

			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.deprecate(waf, "We have logged a warning!", "0.2")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/\[warn\].*DEPRECATED: We have logged a warning!/
--- no_error_log
[error]

=== TEST 3: Deprecate with a matching fatal version
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local base = require "resty.waf.base"
			base.version = "0.1"

			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.deprecate(waf, "We have logged a warning!", "0.1")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/\[warn\].*DEPRECATED: We have logged a warning!/
--- no_error_log
[error]

=== TEST 4: Deprecate with a past fatal version
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local base = require "resty.waf.base"
			base.version = "0.1"

			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.deprecate(waf, "We have logged a warning!", "0.0.9")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 500
--- error_log eval
[qr/\[warn\].*DEPRECATED: We have logged a warning!/,
qr/fatal deprecation version passed/]

