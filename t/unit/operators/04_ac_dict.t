use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Match (individual)
--- config
    location = /t {
        content_by_lua '
			local op = require "lib.operators"
			local match = op.ac_lookup({}, "foo", { "foo", "bar", "baz", "qux" }, { id = 1 })
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
0
--- no_error_log
[error]

=== TEST 2: Match (table)
--- config
    location = /t {
        content_by_lua '
			local op = require "lib.operators"
			local match = op.ac_lookup({}, { "bang", "bash", "qux" }, { "foo", "bar", "baz", "qux" }, { id = 1 })
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
0
--- no_error_log
[error]

=== TEST 3: No match (individual)
--- config
    location = /t {
        content_by_lua '
			local op = require "lib.operators"
			local match = op.ac_lookup({}, "far", { "foo", "bar", "baz", "qux" }, { id = 1 })
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
--- config
    location = /t {
        content_by_lua '
			local op = require "lib.operators"
			local match = op.ac_lookup({}, { "bang", "bash", "quz" }, { "foo", "bar", "baz", "qux" }, { id = 1 })
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

