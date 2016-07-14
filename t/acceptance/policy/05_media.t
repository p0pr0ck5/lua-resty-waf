use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .mpg
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mpg
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 2: Whitelist .mpeg
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mpeg
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 3: Whitelist .mp3
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mp3
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 4: Whitelist .mp4
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mp4
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 5: Whitelist .avi
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.avi
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 6: Whitelist .flv
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.flv
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 7: Whitelist .swf
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.swf
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 8: Whitelist .wma
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.wma
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 9: Do not whitelist unmatched extension (.wmd)
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.wmd
--- error_code: 404
--- no_error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 10: Do not whitelist non-final extension
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.avi.exe
--- error_code: 404
--- no_error_log
Match of rule 11007
Rule action was ACCEPT

