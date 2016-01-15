use Test::Nginx::Socket::Lua;

repeat_each(1);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: GET request with a body
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
foo=bar
--- more_headers
Accept: */*
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
http header: "Content-Length: 7"
"rule":{"id":20002}}

=== TEST 2: POST request does not have a Content-Length header
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
"POST /t HTTP/1.0\r
Host: localhost\r
Accept: */*\r
\nfoo=bar"
--- error_code: 200
--- no_error_log
http header: "Content-Length: 7"
--- error_log
"rule":{"id":20004}}
