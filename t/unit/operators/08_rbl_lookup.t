use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

use lib 't';
use TestDNS;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Match (dummy record)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.4"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			local ctx = { nameservers = { { "127.0.0.1", 2053 } }, _r_id = 12345 }

			local match, value = op.rbl_lookup({}, ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- udp_listen: 2053
--- udp_reply dns
{
	id     => 12345,
	opcode => 0,
	qname  => "4.0.0.127.sbl-xbl.spamhaus.org",
	answer => [{ name => "4.0.0.127.sbl-xbl.spamhaus.org", ipv4 => "127.0.0.4", ttl =>3600 }]
}
--- error_code: 200
--- response_body
true
127.0.0.4
--- no_error_log
[error]
[warn]

=== TEST 2: No match (dummy record)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.1"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			local ctx = { nameservers = { { "127.0.0.1", 2053 } }, _r_id = 12345 }

			local match, value = op.rbl_lookup({}, ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- udp_listen: 2053
--- udp_reply dns
{
	id     => 12345,
	opcode => 0,
	qname  => "1.0.0.127.sbl-xbl.spamhaus.org",
}
--- error_code: 200
--- response_body
false
nil
--- no_error_log
[error]
[warn]

=== TEST 3: No match (bail on no nameservers)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op      = require "resty.waf.operators"
			local ip      = "127.0.0.4"
			local rbl_srv = "sbl-xbl.spamhaus.org"

			local ctx = { nameservers = nil }

			local match, value = op.rbl_lookup({}, ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		}
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
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op      = require "resty.waf.operators"
			local ip      = nil
			local rbl_srv = "sbl-xbl.spamhaus.org"

			local ctx = { nameservers = { "127.0.0.1" } }

			local match, value = op.rbl_lookup({}, ip, rbl_srv, ctx)

			ngx.say(match)
			ngx.say(value)
		}
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

