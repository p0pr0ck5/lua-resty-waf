use Test::Nginx::Socket::Lua;

repeat_each(1);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Request with no Host header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- raw_request eval
"GET /t HTTP/1.0\r
Accept: */*
User-Agent: Hostless
\r\n\n"
--- error_code: 200
--- error_log
"rule":{"id":21001}}
--- no_error_log
[error]

=== TEST 2: Request with no Accept header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- more_headers
User-Agent: Acceptless
--- error_code: 200
--- error_log
"rule":{"id":21004}}
--- no_error_log
[error]

=== TEST 3: Request with empty Accept header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- more_headers
Accept:
--- error_code: 200
--- error_log
"rule":{"id":21006}}
--- no_error_log
[error]

=== TEST 4: Request with no User-Agent header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
"rule":{"id":21007}}
--- no_error_log
[error]

=== TEST 5: Request with empty User-Agent header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- more_headers
User-Agent:
--- error_code: 200
--- error_log
"rule":{"id":21008}}
--- no_error_log
[error]

=== TEST 6: Request contains Content-Length but no Content-Type
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
POST /t
foo=bar
--- more_headers
Accept: */*
User-Agent: Typeless
--- error_code: 200
--- error_log
"rule":{"id":21010}}
--- no_error_log
[error]

=== TEST 7: Request with IP address in Host header
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

			fw:set_option("ignore_rule", 11001)
			fw:set_option("event_log_altered_only", false)
			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- raw_request eval
"GET /t HTTP/1.0\r
Host: 127.0.0.1
Accept: */*
\r\n\n"
--- error_code: 200
--- error_log
"rule":{"id":21011}}
--- no_error_log
[error]

