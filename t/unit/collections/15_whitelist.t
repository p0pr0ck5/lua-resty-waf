use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: WHITELIST collections variable
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("whitelist", "127.0.0.1")
			fw:exec()

			local collections = ngx.ctx.collections
			local whitelist   = collections.WHITELIST(fw)

			for k, v in ipairs(whitelist) do
				ngx.say(v)
			end
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- response_body
127.0.0.1
--- no_error_log
[error]

=== TEST 2: WHITELIST collections variable (type verification)
--- http_config
	lua_shared_dict storage 10m;
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local FreeWAF     = require "fw"
			local fw          = FreeWAF:new()

			ngx.say(type(collections.WHITELIST))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
function
--- no_error_log
[error]

=== TEST 3: WHITELIST collections variable (return type verification)
--- http_config
	lua_shared_dict storage 10m;
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local FreeWAF     = require "fw"
			local fw          = FreeWAF:new()

			ngx.say(type(collections.WHITELIST(fw)))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

