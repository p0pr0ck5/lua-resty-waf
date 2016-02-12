use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Call init with no options
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
[lua] log.lua:8: log()

=== TEST 2: Inherit init options
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.default_option("debug", true)
		FreeWAF.default_option("debug_log_level", ngx.DEBUG)
		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
[lua] log.lua:8: log()
--- no_error_log
[error]

