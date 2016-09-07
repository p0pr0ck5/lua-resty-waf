use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: md5
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 1})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local util      = require "resty.waf.util"
			local value     = "hello world"
			local transform = lookup.lookup["md5"]({}, value)
			ngx.say(util.hex_encode(transform))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
5eb63bbbe01eeed093cb22bb8f5acdc3
--- no_error_log
[error]

=== TEST 2: hex-encoded md5 matches ngx.md5
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 1})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local util      = require "resty.waf.util"
			local value     = "hello world"
			local transform = lookup.lookup["md5"]({}, value)
			ngx.say(util.hex_encode(transform) == ngx.md5(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: sha1
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 1})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local util      = require "resty.waf.util"
			local value     = "hello world"
			local transform = lookup.lookup["sha1"]({}, value)
			ngx.say(util.hex_encode(transform))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
2aae6c35c94fcfb415dbe95f408b9ce91ee846ed
--- no_error_log
[error]

