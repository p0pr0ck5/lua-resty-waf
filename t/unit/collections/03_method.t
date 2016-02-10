use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: METHOD collections variable (GET)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.METHOD)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
GET
--- no_error_log
[error]

=== TEST 2: METHOD collections variable (POST)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.METHOD)
		';
	}
--- request
POST /t
--- error_code: 200
--- response_body
POST
--- no_error_log
[error]

=== TEST 3: METHOD collections variable (HEAD)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()

			local collections = ngx.ctx.collections
			ngx.header["X-Method"] = collections.METHOD
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
HEAD /t
--- error_code: 200
--- response_headers
X-Method: HEAD
--- no_error_log
[error]

=== TEST 4: METHOD collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.METHOD))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

