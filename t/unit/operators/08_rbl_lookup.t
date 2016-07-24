use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Match (dummy record)
--- config
    location = /t {
        content_by_lua '
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.4"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			-- this makes this test very fragile
			-- this is one record for 0.ns.spamhaus.org.
			local ctx = { nameservers = { "194.104.0.140" } }

			local match, value = op.rbl_lookup(ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
127.0.0.4
--- no_error_log
[error]
[warn]

=== TEST 2: No match (dummy record)
--- config
    location = /t {
        content_by_lua '
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.1"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			-- this makes this test very fragile
			-- this is one record for 0.ns.spamhaus.org.
			local ctx = { nameservers = { "194.104.0.140" } }

			local match, value = op.rbl_lookup(ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
nil
--- no_error_log
[error]
[warn]

=== TEST 3: No match (bail on no nameservers)
--- config
    location = /t {
        content_by_lua '
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.4"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			-- this makes this test very fragile
			-- this is one record for 0.ns.spamhaus.org.
			local ctx = { nameservers = nil }

			local match, value = op.rbl_lookup(ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
nil
--- no_error_log
[error]
[warn]

=== TEST 4: No match (invalid IP)
--- config
    location = /t {
        content_by_lua '
			local op      = require "resty.waf.operators"
			local ip      = nil
			local rbl_srv = "sbl-xbl.spamhaus.org"

			-- this makes this test very fragile
			-- this is one record for 0.ns.spamhaus.org.
			local ctx = { nameservers = { "194.104.0.140" } }

			local match, value = op.rbl_lookup(ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
nil
--- no_error_log
[error]
[warn]

