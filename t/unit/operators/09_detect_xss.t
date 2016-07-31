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
			local op = require "resty.waf.operators"
			local match, value = op.detect_xss("\'><script><alert(1)</script>")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 2: Match (table)
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local match, value = op.detect_xss({"this string has the word select and alert", "\'><script><alert(1)</script>"})
			ngx.say(match)
		';
	}
--- request
GET /t?f
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: No match (individual)
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local match, value = op.detect_xss("this string has the word select and alert")
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: No match (table)
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local match, value = op.detect_xss({"this string has the word select and alert", "so does select this alert one"})
			ngx.say(match)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 5: Return types
--- config
    location = /t {
        content_by_lua '
			local op = require "resty.waf.operators"
			local match, value = op.detect_xss("\'><script><alert(1)</script>")
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
