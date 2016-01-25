use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Logs ngx.var
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
			fw:set_option("mode", "ACTIVE")
			fw:set_option("event_log_ngx_vars", "args")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- error_log
"ngx":{
"args":"foo=alert(1)"

=== TEST 2: Logs request arguments
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
			fw:set_option("mode", "ACTIVE")
			fw:set_option("event_log_request_arguments", true)
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- error_log
"uri_args":{"foo":"alert(1)"}
--- no_error_log
[error]
