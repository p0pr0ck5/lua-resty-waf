use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: build a valid query
--- config
	location /t {
		content_by_lua '
			local util    = require "resty.waf.util"
			local ip      = "127.0.0.1"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
1.0.0.127.sbl-xbl.spamhaus.org
--- no_error_log
[error]

=== TEST 2: build an invalid query (bad ip type)
--- config
	location /t {
		content_by_lua '
			local util    = require "resty.waf.util"
			local ip      = { "127.0.0.1" }
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 3: build an invalid query (invalid ip string)
--- config
	location /t {
		content_by_lua '
			local util    = require "resty.waf.util"
			local ip      = "im.not.an.ip"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: build a valid query with an invalid IP
# we don't check if we're given a -valid- IPv4 address, because our query to the rbl server should just return false
--- config
	location /t {
		content_by_lua '
			local util    = require "resty.waf.util"
			local ip      = "999.999.999.999"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
999.999.999.999.sbl-xbl.spamhaus.org
--- no_error_log
[error]

