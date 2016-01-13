use Test::Nginx::Socket::Lua;

repeat_each(1);
plan tests => repeat_each() * 6 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Show the design of the resource
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()


			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
You've entered the following: 'bar'
--- no_error_log
[error]

=== TEST 2: Show a reflected XSS vulnerability
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()


			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 200
--- response_body
You've entered the following: '<script>alert(1)</script>'
--- no_error_log
[error]

=== TEST 3: Log a reflected XSS attack in SIMULATE mode
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()


			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 200
--- response_body
You've entered the following: '<script>alert(1)</script>'
--- error_log
"rule":{"id":42043}}
"rule":{"id":42059}}
"rule":{"id":42069}}
"rule":{"id":42076}}
"rule":{"id":42083}}
"rule":{"id":99001}}
--- no_error_log
[error]

=== TEST 4: Log and deny a reflected XSS attack in ACTIVE mode
--- http_config
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()


			ngx.say("You\'ve entered the following: \'" .. args.foo .. "\'")
		';
	}
--- request
GET /t?foo=<script>alert(1)</script>
--- error_code: 403
--- response_body_unlike
You've entered the following: '<script>alert\(1\)</script>'
--- error_log
"rule":{"id":42043}}
"rule":{"id":42059}}
"rule":{"id":42069}}
"rule":{"id":42076}}
"rule":{"id":42083}}
"rule":{"id":99001}}
--- no_error_log
[error]

