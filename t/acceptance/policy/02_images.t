use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Skip whitelisting of non-passive requests
--- http_config
	init_by_lua '
		local FreeWAF = require "fw"
		FreeWAF.init()
	';
--- config
	access_by_lua '
		local FreeWAF = require "fw"
		local fw      = FreeWAF:new()

		fw:set_option("debug", true)
		fw:set_option("mode", "ACTIVE")
		fw:exec()
	';

	location /t {
		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request
POST /t
foo=bar
--- error_code: 200
--- error_log
Match of rule 11003
--- no_error_log
[error]

=== TEST 2: Whitelist .jpg
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
GET /foo.jpg
--- error_code: 404
--- error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 3: Whitelist .jpeg
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
GET /foo.jpeg
--- error_code: 404
--- error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 4: Whitelist .png
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
GET /foo.png
--- error_code: 404
--- error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 5: Whitelist .gif
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
GET /foo.gif
--- error_code: 404
--- error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 6: Whitelist .ico
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
GET /foo.ico
--- error_code: 404
--- error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 7: Do not whitelist unmatched extension (.tiff)
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
GET /foo.tiff
--- error_code: 404
--- no_error_log
Match of rule 11004
An explicit ACCEPT was sent

=== TEST 8: Do not whitelist non-final extension
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
GET /foo.jpg.exe
--- error_code: 404
--- no_error_log
Match of rule 11004
An explicit ACCEPT was sent

