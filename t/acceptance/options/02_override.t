use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Local set_option overrides implicit default
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

=== TEST 2: Local set_option overrides explicit default_option
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

			fw:set_option("debug", false)
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

=== TEST 3: Override of implicit default only affects defined scope
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

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}

	location /s {
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

=== TEST 4: Override of implicit default only affects defined scope (part 2)
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

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}

	location /s {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /s
--- error_code: 200
--- no_error_log
[error]
[lua] log.lua:8: log()

=== TEST 5: Override of explicit default only affects defined scope
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

			fw:set_option("debug", false)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}

	location /s {
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

=== TEST 6: Override of explicit default only affects defined scope (part 2)
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

			fw:set_option("debug", false)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}

	location /s {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /s
--- error_code: 200
--- error_log
[lua] log.lua:8: log()
--- no_error_log
[error]

=== TEST 7: Append to a table value option
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
			fw:set_option("ignore_ruleset", 10000)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
Beginning ruleset 10000,
Beginning ruleset 11000,

