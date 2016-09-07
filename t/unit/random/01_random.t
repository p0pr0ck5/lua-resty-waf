use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Generate 8 hex-encoded random bytes
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
		content_by_lua '
			local random = require "resty.waf.random"
			local string = random.random_bytes(8)

			ngx.say(string)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body_like
^[0-9a-f]{16}$
--- no_error_log
[error]

=== TEST 2: Generate 16 hex-encoded random bytes
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
		content_by_lua '
			local random = require "resty.waf.random"
			local string = random.random_bytes(16)

			ngx.say(string)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body_like
^[0-9a-f]{32}$
--- no_error_log
[error]

=== TEST 3: Two random strings should not be equal
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
		content_by_lua '
			local random = require "resty.waf.random"
			local str1   = random.random_bytes(8)
			local str2   = random.random_bytes(8)

			ngx.say(str1 == str2)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

