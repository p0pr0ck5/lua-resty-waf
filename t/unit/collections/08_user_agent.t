use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: USER_AGENT collections variable
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.USER_AGENT)
		';
	}
--- request
GET /t
--- more_headers
User-Agent: FreeWAF Test
--- error_code: 200
--- response_body
FreeWAF Test
--- no_error_log
[error]

=== TEST 2: USER_AGENT collections variable (User-Agent not sent)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.USER_AGENT)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 3: USER_AGENT collections variable (type verification)
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.USER_AGENT))
		';
	}
--- request
GET /t
--- error_code: 200
--- more_headers
User-Agent: FreeWAF Test
--- response_body
string
--- no_error_log
[error]

