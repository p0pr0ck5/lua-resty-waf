use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: No whitelisted IPs
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
Match of rule 10001

=== TEST 2: Client IP is whitelisted
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("whitelist", "127.0.0.1")
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Match of rule 10001
--- no_error_log
[error]

=== TEST 3: Client IP is among whitelisted IPs
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("whitelist", { "127.0.0.1", "1.2.3.4", "5.6.7.8" })
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Match of rule 10001
--- no_error_log
[error]

=== TEST 4: Client IP is not among whitelisted IPs
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("whitelist", { "127.0.0.2", "1.2.3.4", "5.6.7.8" })
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 10001
