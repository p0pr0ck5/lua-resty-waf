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
			local greater = require "FreeWAF.lib.operators"
        ';
    }
--- request
    GET /t
--- response_body
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: integer greater
--- config
    location = /t {
        content_by_lua '
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, 2, 1))
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
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, 1, 1))
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: integer less
--- config
    location = /t {
        content_by_lua '
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, 1, 2))
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: table integer greater
--- config
    location = /t {
        content_by_lua '
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, {0, 1, 2}, 1))
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
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, {-1, 0, 1}, 1))
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: table integer less
--- config
    location = /t {
        content_by_lua '
			local op = require "FreeWAF.lib.operators"
			ngx.say(op.greater({}, {-1, 0, 1}, 2))
        ';
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

