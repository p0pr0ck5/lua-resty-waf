use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 15;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Examine the structure of a log entry
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
GET /t
--- more_headers
User-Agent: FreeWAF Dummy
--- error_code: 200
--- error_log eval
[
qr/"client":"127.0.0.1",/,
qr/"method":"GET",/,
qr/"uri":"\\\/t",/,
qr/"alerts":\[/,
qr/"score":/,
qr/"id":"[a-f0-9]{20}"/
]
--- no_error_log
[error]

=== TEST 2: Do not log a request that was not altered
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
GET /t?a=b
--- error_code: 200
--- error_log
Not logging a request that wasn't altered
--- no_error_log eval
[
qr/"client":"127.0.0.1",/,
qr/"method":"GET",/,
qr/"uri":"\\\/t",/,
qr/"alerts":\[/,
qr/"score":/,
qr/"id":"[a-f0-9]{20}"/
]
--- no_error_log
[error]

=== TEST 3: Do not log a request in which no rules matched
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
			fw:set_option("event_log_altered_only", false)
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
GET /t?a=b
--- more_headers
Accept: */*
User-Agent: Test
--- error_code: 200
--- error_log
Not logging a request that had no rule alerts
--- no_error_log eval
[
qr/"client":"127.0.0.1",/,
qr/"method":"GET",/,
qr/"uri":"\\\/t",/,
qr/"alerts":\[/,
qr/"score":/,
qr/"id":"[a-f0-9]{20}"/
]
--- no_error_log
[error]

