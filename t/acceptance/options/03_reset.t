use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Reset a simple value
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.default_option("debug", true)
		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:reset_option("debug")
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

=== TEST 2: Reset a simple value and set it again
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.default_option("debug", true)
		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:reset_option("debug")
			fw:set_option("debug", true)
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

=== TEST 3: Reset a table value
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.default_option("ignore_ruleset", 11000)
		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:reset_option("ignore_ruleset")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning ruleset 11000,
--- no_error_log
[error]

=== TEST 4: Reset a table value and set it again
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"

		FreeWAF.default_option("ignore_ruleset", 11000)
		FreeWAF.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:reset_option("ignore_ruleset")
			fw:set_option("ignore_ruleset", 10000)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning ruleset 11000,
--- no_error_log
[error]
Beginning ruleset 10000,

