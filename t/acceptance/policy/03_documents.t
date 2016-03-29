use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .doc
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.doc
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 2: Whitelist .pdf
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.pdf
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 3: Whitelist .txt
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.txt
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 4: Whitelist .xls
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.xls
--- error_code: 404
--- error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 5: Do not whitelist unmatched extension (.ppt)
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.ppt
--- error_code: 404
--- no_error_log
Match of rule 11005
Rule action was ACCEPT

=== TEST 6: Do not whitelist non-final extension
--- config
	access_by_lua '
		local lua_resty_waf = require "waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.doc.exe
--- error_code: 404
--- no_error_log
Match of rule 11005
Rule action was ACCEPT

