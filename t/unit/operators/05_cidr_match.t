use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Match against one CIDR
--- config
    location = /t {
        content_by_lua '
			local iputils  = require "inc.resty.iputils"
			local op       = require "lib.operators"

			local cidr = "192.168.0.0/16"

			local match = op.cidr_match("192.168.0.1", cidr)
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

=== TEST 2: Match against multiple CIDRs
--- config
    location = /t {
        content_by_lua '
			local iputils  = require "inc.resty.iputils"
			local op       = require "lib.operators"

			local cidrs = { "192.168.0.0/16", "192.169.0.0/16" }

			local match = op.cidr_match("192.168.0.1", cidrs)
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

=== TEST 3: No natch against one CIDR
--- config
    location = /t {
        content_by_lua '
			local iputils  = require "inc.resty.iputils"
			local op       = require "lib.operators"

			local cidr = "192.168.0.0/16"

			local match = op.cidr_match("172.16.31.255", cidr)
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

=== TEST 4: No match against multiple CIDRs
--- config
    location = /t {
        content_by_lua '
			local iputils  = require "inc.resty.iputils"
			local op       = require "lib.operators"

			local cidrs= { "192.168.0.0/16", "192.169.0.0/16" }

			local match = op.cidr_match("172.16.31.255", cidrs)
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

=== TEST 5: Attempt match of non-IP
--- config
    location = /t {
        content_by_lua '
			local iputils  = require "inc.resty.iputils"
			local op       = require "lib.operators"

			local cidr = "192.168.0.0/16"

			local match = op.cidr_match("foobar", cidr)
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

