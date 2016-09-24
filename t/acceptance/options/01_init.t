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

=== TEST 1: Call init with no options
--- http_config eval
$::HttpConfig . q#
	init_by_lua '
		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.init()
	';
#
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
[lua] log.lua:12: log()

=== TEST 2: Inherit init options
--- http_config eval
$::HttpConfig . q#
	init_by_lua '
		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.default_option("debug", true)
		lua_resty_waf.default_option("debug_log_level", ngx.DEBUG)
		lua_resty_waf.init()
	';
#
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
[lua] log.lua:12: log()
--- no_error_log
[error]

