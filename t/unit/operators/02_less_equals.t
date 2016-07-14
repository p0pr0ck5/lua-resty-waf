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
			local less = require "resty.waf.operators"
        ';
    }
--- request
    GET /t
--- response_body
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: integer less
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals(1, 2)
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: integer equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals(1, 1)
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: integer greater
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals(2, 1)
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: table integer less
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals({0, 1, 2}, 1)
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: table integer equals
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = (op.less_equals({1, 2, 3}, 1))
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: table integer greater
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals({1, 2, 3}, 0)
			ngx.say(less)
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: return values
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals(1, 2)
			ngx.say(less)
			ngx.say(value)
        ';
    }
--- request
    GET /t
--- response_body
true
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: return value types
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local less, value = op.less_equals(1, 2)
			ngx.say(type(less))
			ngx.say(type(value))
        ';
    }
--- request
    GET /t
--- response_body
boolean
number
--- error_code: 200
--- no_error_log
[error]

