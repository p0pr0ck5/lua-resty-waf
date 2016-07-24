use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location = /t {
        content_by_lua '
			local equals = require "resty.waf.operators"
        ';
    }
--- request
    GET /t
--- response_body
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: integer equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals(1, 1)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: integer not equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals(1, 2)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: string equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: string not equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "bar")
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: integer table equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals({3, 2, 1}, 1)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: integer table not equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals({3, 2, 0}, 1)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: string table equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals({"bar", "foo"}, "foo")
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: string table not equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals({"bar", "baz"}, "foo")
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: string "nil" not equals nil
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("nil", nil)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 11: string not equals integer
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("7", 7)
			ngx.say(equals)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 12: return values
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(equals)
			ngx.say(value)
        ';
    }
--- request
    GET /t
--- response_body
true
foo
--- error_code: 200
--- no_error_log
[error]

=== TEST 13: return value types
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(type(equals))
			ngx.say(type(value))
        ';
    }
--- request
    GET /t
--- response_body
boolean
string
--- error_code: 200
--- no_error_log
[error]

