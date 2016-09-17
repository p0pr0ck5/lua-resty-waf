use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Match (individual)
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(value[0])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello
--- no_error_log
[error]

=== TEST 2: Match (table)
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "hello, 1234"}, "([a-z])[a-z]+")
			ngx.say(value[0])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello
--- no_error_log
[error]

=== TEST 3: No match (individual)
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, "HELLO, 1234", "([a-z])[a-z]+")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 4: No match (table)
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "HELLO, 1234"}, "([a-z])[a-z]+")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 5: Invalid pattern
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match = op.regex({ _pcre_flags = "" }, "hello, 1234", "+([a-z])[a-z]+")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
error in ngx.re.match:
--- no_error_log
[error]

=== TEST 6: Return values
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, "hello, 1234", "([a-z])([a-z]+)")
			ngx.say(match)
			ngx.say(value[0])
			for k in ipairs(value) do
				ngx.say(value[k])
			end
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
hello
h
ello
--- no_error_log
[error]

=== TEST 7: Return value types
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
    location = /t {
        content_by_lua '
			local op    = require "resty.waf.operators"
			local match, value = op.regex({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(type(match))
			ngx.say(type(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
boolean
table
--- no_error_log
[error]

