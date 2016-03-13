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
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(value)
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
--- config
    location = /t {
        content_by_lua '
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "hello, 1234"}, "([a-z])[a-z]+")
			ngx.say(value)
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
--- config
    location = /t {
        content_by_lua '
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, "HELLO, 1234", "([a-z])[a-z]+")
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
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "HELLO, 1234"}, "([a-z])[a-z]+")
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
--- config
    location = /t {
        content_by_lua '
			local op    = require "lib.operators"
			local match = op.regex_match({ _pcre_flags = "" }, "hello, 1234", "+([a-z])[a-z]+")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
error in regex_match:
--- no_error_log
[error]

=== TEST 6: Return values
--- config
    location = /t {
        content_by_lua '
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(match)
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
hello
--- no_error_log
[error]

=== TEST 7: Return value types
--- config
    location = /t {
        content_by_lua '
			local op    = require "lib.operators"
			local match, value = op.regex_match({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(type(match))
			ngx.say(type(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
boolean
string
--- no_error_log
[error]

