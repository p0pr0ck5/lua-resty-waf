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

=== TEST 1a: Match (individual)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- no_error_log
[error]

=== TEST 1b: Match (individual)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, "  a hello, 1234", "([a-z])[a-z]+")
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
5
--- no_error_log
[error]

=== TEST 2a: Match (table)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "hello, 1234"}, "([a-z])[a-z]+")
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- no_error_log
[error]

=== TEST 2b: Match (table)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, { "99-99-99", " hello, 1234", "hello, 1234" }, "^([a-z])[a-z]+")
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- no_error_log
[error]

=== TEST 3: No match (individual)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, "HELLO, 1234", "([a-z])[a-z]+")
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

=== TEST 4: No match (table)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, { "99-99-99", "	_\\\\", "HELLO, 1234"}, "([a-z])[a-z]+")
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

=== TEST 5: Invalid pattern
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match = op.refind({ _pcre_flags = "" }, "hello, 1234", "+([a-z])[a-z]+")
			ngx.say(match)
		}
	}
--- request
GET /t
--- error_code: 200
--- error_log
error in ngx.re.find:
--- no_error_log
[error]

=== TEST 6: Return values
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, "hello, 1234", "([a-z])([a-z]+)")
			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
1
--- no_error_log
[error]

=== TEST 7: Return value types
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op    = require "resty.waf.operators"
			local match, value = op.refind({ _pcre_flags = "" }, "hello, 1234", "([a-z])[a-z]+")
			ngx.say(type(match))
			ngx.say(type(value))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
boolean
number
--- no_error_log
[error]

