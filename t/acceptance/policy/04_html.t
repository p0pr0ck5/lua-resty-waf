use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .css
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.css
--- error_code: 404
--- error_log
Match of rule 11006
Rule action was ACCEPT

=== TEST 2: Whitelist .js
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.js
--- error_code: 404
--- error_log
Match of rule 11006
Rule action was ACCEPT

=== TEST 3: Whitelist .html
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.html
--- error_code: 404
--- error_log
Match of rule 11006
Rule action was ACCEPT

=== TEST 4: Whitelist .htm
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.htm
--- error_code: 404
--- error_log
Match of rule 11006
Rule action was ACCEPT

=== TEST 5: Do not whitelist unmatched extension (.shtml)
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.shtml
--- error_code: 404
--- no_error_log
Match of rule 11006
Rule action was ACCEPT

=== TEST 6: Do not whitelist non-final extension
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("ignore_rule", 11001)
		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';
--- request
GET /foo.css.exe
--- error_code: 404
--- no_error_log
Match of rule 11006
Rule action was ACCEPT

