use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_LINE collections variable (simple)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_LINE)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
GET /t HTTP/1.1
--- no_error_log
[error]

=== TEST 2: REQUEST_LINE collections variable (single pair)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_LINE)
		';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- response_body
GET /t?foo=bar HTTP/1.1
--- no_error_log
[error]

=== TEST 3: REQUEST_LINE collections variable (complex)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_LINE)
		';
	}
--- request
GET /t?foo=bar&foo=bat&frob&qux=
--- error_code: 200
--- response_body
GET /t?foo=bar&foo=bat&frob&qux= HTTP/1.1
--- no_error_log
[error]

=== TEST 4: REQUEST_LINE collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_LINE))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

