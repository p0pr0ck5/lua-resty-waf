use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 6;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Log ngx.var to event log
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

=== TEST 2: Do not log ngx.var if option is unset
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
--- no_error_log
"ngx":{
"args":"foo=alert(1)"

=== TEST 3: Log request arguments
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

=== TEST 4: Do not log request arguments if option is unset
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
--- no_error_log
"uri_args":{"foo":"alert(1)"}
[error]

=== TEST 5: Log request headers
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
			fw:set_option("event_log_request_headers", true)
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
--- more_headers
X-Foo: Bar
--- error_code: 403
--- error_log
"request_headers":{
"host":"localhost",
"x-foo":"Bar",
---  no_error_log
[error]

