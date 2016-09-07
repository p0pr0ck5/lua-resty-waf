use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: compress_whitespace
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
			local value     = "how  	are	you    doing?"
			local transform = lookup.lookup["compress_whitespace"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
how are you doing?
--- no_error_log
[error]

=== TEST 2: remove_whitespace
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
			local value     = "how  	are	you    doing?"
			local transform = lookup.lookup["remove_whitespace"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
howareyoudoing?
--- no_error_log
[error]

