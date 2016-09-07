use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Existing key (string)
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
			local util = require "resty.waf.util"
			local t    = { foo = "bar", qux = "frob" }
			local val  = util.table_has_key("foo", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 2: Existing key (integer)
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
			local util = require "resty.waf.util"
			local t    = { "foo", "bar", "qux", "frob" }
			local val  = util.table_has_key(1, t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: Non existing key (string)
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
			local util = require "resty.waf.util"
			local t    = { foo = "bar", qux = "frob" }
			local val  = util.table_has_key("baz", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: Non existing key (integer)
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
			local util = require "resty.waf.util"
			local t    = { "foo", "bar", "qux", "frob" }
			local val  = util.table_has_key(0, t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 5: Haystack is not a table
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
			local util = require "resty.waf.util"
			local t    = "foo, bar"
			local val  = util.table_has_key("foo", t)
			ngx.say(val)
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log
fatal_fail
Cannot search for a needle when haystack is type string
