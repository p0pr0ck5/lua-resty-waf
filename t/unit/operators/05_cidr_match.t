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

=== TEST 1: Match against one CIDR
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op   = require "resty.waf.operators"
			local cidr = "192.168.0.0/16"

			local match, value = op.cidr_match("192.168.0.1", cidr)
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 2: Match against multiple CIDRs
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local cidrs = { "192.168.0.0/16", "192.169.0.0/16" }

			local match, value = op.cidr_match("192.168.0.1", cidrs)
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 3: No natch against one CIDR
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op   = require "resty.waf.operators"
			local cidr = "192.168.0.0/16"

			local match, value = op.cidr_match("172.16.31.255", cidr)
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: No match against multiple CIDRs
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local cidrs = { "192.168.0.0/16", "192.169.0.0/16" }

			local match, value = op.cidr_match("172.16.31.255", cidrs)
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 5: Attempt match of non-IP
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op   = require "resty.waf.operators"
			local cidr = "192.168.0.0/16"

			local match, value = op.cidr_match("foobar", cidr)
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 6: Return values
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op   = require "resty.waf.operators"
			local cidr = "192.168.0.0/16"

			local match, value = op.cidr_match("192.168.0.1", cidr)
			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
192.168.0.1
--- no_error_log
[error]

=== TEST 7: Return value types
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op   = require "resty.waf.operators"
			local cidr = "192.168.0.0/16"

			local match, value = op.cidr_match("192.168.0.1", cidr)
			ngx.say(type(match))
			ngx.say(type(value))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
boolean
string
--- no_error_log
[error]

