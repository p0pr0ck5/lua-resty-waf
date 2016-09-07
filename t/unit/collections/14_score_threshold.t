use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: SCORE_THRESHOLD collections variable
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local lua_resty_waf     = require "resty.waf"
			local waf               = lua_resty_waf:new()

			ngx.say(collections.SCORE_THRESHOLD)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
5
--- no_error_log
[error]

=== TEST 2: SCORE_THRESHOLD collections variable (type verification)
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.SCORE_THRESHOLD))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
number
--- no_error_log
[error]

=== TEST 3: SCORE_THRESHOLD collections variable (return type verification)
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections
			local lua_resty_waf     = require "resty.waf"
			local waf               = lua_resty_waf:new()

			ngx.say(type(collections.SCORE_THRESHOLD))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
number
--- no_error_log
[error]

