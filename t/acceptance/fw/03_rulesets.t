use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 15 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Runs the default rulesets
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
Beginning ruleset 10000,
Beginning ruleset 11000,
Beginning ruleset 20000,
Beginning ruleset 21000,
Beginning ruleset 35000,
Beginning ruleset 40000,
Beginning ruleset 41000,
Beginning ruleset 42000,
Beginning ruleset 90000,
Beginning ruleset 99000,
--- no_error_log
[error]
Beginning ruleset 1000,
Adding ruleset
Ignoring ruleset

=== TEST 2: Ignore a ruleset
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("ignore_ruleset", 90000)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Ignoring ruleset 90000,
Beginning ruleset 10000,
Beginning ruleset 11000,
Beginning ruleset 20000,
Beginning ruleset 21000,
Beginning ruleset 35000,
Beginning ruleset 40000,
Beginning ruleset 41000,
Beginning ruleset 42000,
Beginning ruleset 99000,
--- no_error_log
[error]
Beginning ruleset 1000,
Beginning ruleset 90000,
Adding ruleset

=== TEST 3: Add a custom ruleset
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("add_ruleset", 1000)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Adding ruleset 1000
Beginning ruleset 1000,
Beginning ruleset 10000,
Beginning ruleset 11000,
Beginning ruleset 20000,
Beginning ruleset 21000,
Beginning ruleset 35000,
Beginning ruleset 40000,
Beginning ruleset 41000,
Beginning ruleset 42000,
Beginning ruleset 99000,
--- no_error_log
[error]
Ignoring ruleset
