use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .mpg
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
GET /foo.mpg
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 2: Whitelist .mpeg
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
GET /foo.mpeg
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 3: Whitelist .mp3
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
GET /foo.mp3
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 4: Whitelist .mp4
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
GET /foo.mp4
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 5: Whitelist .avi
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
GET /foo.avi
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 6: Whitelist .flv
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
GET /foo.flv
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 7: Whitelist .swf
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
GET /foo.swf
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 8: Whitelist .wma
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
GET /foo.wma
--- error_code: 404
--- error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 9: Do not whitelist unmatched extension (.wmd)
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
GET /foo.wmd
--- error_code: 404
--- no_error_log
Match of rule 11007
An explicit ACCEPT was sent

=== TEST 10: Do not whitelist non-final extension
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
GET /foo.avi.exe
--- error_code: 404
--- no_error_log
Match of rule 11007
An explicit ACCEPT was sent

