use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Parse a JSON string successfully
--- config
    location = /t {
        content_by_lua '
			local util = require "lib.util"
			local str  = [=[{"foo":"bar","baz":["bat","qux"]}]=]

			local parse, err = util.parse_ruleset(str)

			ngx.say(parse.foo)
			ngx.say(parse.baz[1])
			ngx.say(type(parse))
			ngx.say(err)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
bat
table
nil
--- no_error_log
[error]

=== TEST 2: Parse a bad JSON string
--- config
    location = /t {
        content_by_lua '
			local util = require "lib.util"
			local str  = [=[{"foo":"bar","baz":["bat","qux]}]=]

			local parse, err = util.parse_ruleset(str)

			ngx.say(type(parse))
			ngx.say(err)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
could not decode {"foo":"bar","baz":["bat","qux]}
--- no_error_log
[error]

