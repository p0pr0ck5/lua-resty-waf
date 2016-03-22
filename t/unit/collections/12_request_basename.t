use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: REQUEST_BASENAME collections variable
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_BASENAME)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
/t
--- no_error_log
[error]

=== TEST 2: REQUEST_BASENAME collections variable (longer URI)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say("Hello world!")
		';
	}

	location /foo/bar {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.REQUEST_BASENAME)
		';
	}
--- request
GET /foo/bar/index.php
--- error_code: 200
--- response_body
/index.php
--- no_error_log
[error]

=== TEST 3: REQUEST_BASENAME collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.REQUEST_BASENAME))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
string
--- no_error_log
[error]

