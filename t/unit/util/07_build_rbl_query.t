use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: build a valid query
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util    = require "resty.waf.util"
			local ip      = "127.0.0.1"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
1.0.0.127.sbl-xbl.spamhaus.org
--- no_error_log
[error]

=== TEST 2: build an invalid query (bad ip type)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util    = require "resty.waf.util"
			local ip      = { "127.0.0.1" }
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 3: build an invalid query (invalid ip string)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util    = require "resty.waf.util"
			local ip      = "im.not.an.ip"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		}
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
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util    = require "resty.waf.util"
			local ip      = "999.999.999.999"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			ngx.say(util.build_rbl_query(ip, rbl_srv))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
999.999.999.999.sbl-xbl.spamhaus.org
--- no_error_log
[error]

