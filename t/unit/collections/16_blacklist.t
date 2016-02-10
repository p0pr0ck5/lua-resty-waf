use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: BLACKLIST collections variable
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("blacklist", "127.0.0.1")
			fw:exec()

			local collections = ngx.ctx.collections
			local blacklist   = collections.BLACKLIST(fw)

			for k, v in ipairs(blacklist) do
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

=== TEST 2: BLACKLIST collections variable (type verification)
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

			ngx.say(type(collections.BLACKLIST))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
function
--- no_error_log
[error]

=== TEST 3: BLACKLIST collections variable (return type verification)
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

			ngx.say(type(collections.BLACKLIST(fw)))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

