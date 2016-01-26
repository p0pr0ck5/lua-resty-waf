use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .doc
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
GET /foo.doc
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 2: Whitelist .pdf
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
GET /foo.pdf
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 3: Whitelist .txt
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
GET /foo.txt
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 4: Whitelist .xls
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
GET /foo.xls
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 5: Do not whitelist unmatched extension (.ppt)
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
GET /foo.ppt
--- error_code: 404
--- no_error_log
Match of rule 11005
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
GET /foo.doc.exe
--- error_code: 404
--- no_error_log
Match of rule 11005
Rule action was ACCEPT

