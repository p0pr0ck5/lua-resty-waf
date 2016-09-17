use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Reset a simple value
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.default_option("debug", true)
		lua_resty_waf.init()
	';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:reset_option("debug")
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

=== TEST 2: Reset a simple value and set it again
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.default_option("debug", true)
		lua_resty_waf.init()
	';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:reset_option("debug")
			waf:set_option("debug", true)
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

=== TEST 3: Reset a table value
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.default_option("ignore_ruleset", 11000)
		lua_resty_waf.init()
	';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:reset_option("ignore_ruleset")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning ruleset 11000_whitelist,
--- no_error_log
[error]

=== TEST 4: Reset a table value and set it again
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"

		lua_resty_waf.default_option("ignore_ruleset", "11000_whitelist")
		lua_resty_waf.init()
	';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:reset_option("ignore_ruleset")
			waf:set_option("ignore_ruleset", "extra")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning ruleset 11000_whitelist,
--- no_error_log
[error]
Beginning ruleset extra,

