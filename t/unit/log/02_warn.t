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

=== TEST 1: Log a warning
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.warn(waf, "We have logged a warning!")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/\[warn\].*We have logged a warning!/
--- no_error_log
[error]

=== TEST 2: Log a warning at INFO level
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.warn(waf, "We have logged a warning!")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- log_level
info
--- request
GET /t
--- error_code: 200
--- error_log eval
qr/\[warn\].*We have logged a warning!/
--- no_error_log
[error]

=== TEST 3: Log a warning at ERROR level
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local logger        = require "resty.waf.log"

			logger.warn(waf, "We have logged a warning!")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- log_level
error
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
We have logged a warning!

