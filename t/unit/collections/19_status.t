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

=== TEST 1: STATUS collections variable (200)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		header_filter_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. collections.STATUS .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"200" while logging request
--- no_error_log
[error]

=== TEST 2: STATUS collections variable (403)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_FORBIDDEN)';

		header_filter_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. collections.STATUS .. [["]])
		';
	}
--- request
GET /t
--- error_code: 403
--- error_log
"403" while logging request
--- no_error_log
[error]

=== TEST 3: STATUS collections variable (type verification)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		header_filter_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		log_by_lua '
			local collections = ngx.ctx.collections

			ngx.log(ngx.INFO, [["]] .. type(collections.STATUS) .. [["]])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"number" while logging request
--- no_error_log
[error]

