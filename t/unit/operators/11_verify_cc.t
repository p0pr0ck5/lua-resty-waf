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

=== TEST 1: Match (individual)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				'4929610868617230',
				[[^\d+$]]
			)

			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
4929610868617230
--- no_error_log
[error]

=== TEST 2: Match (table)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				{ 'foo', '4929610868617230' },
				[[^\d+$]]
			)

			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
4929610868617230
--- no_error_log
[error]

=== TEST 3: No match (individual)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				'4929610868617231',
				[[^\d+$]]
			)

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

=== TEST 4: No match (table)
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				{ 'foo', '4929610868617231' },
				[[^\d+$]]
			)

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

=== TEST 5: Replace non-digit character
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				"this is my cc: 4929-6108-6861-7230\n",
				[[(?:\d{4}-){3}\d{4}]]
			)

			ngx.say(match)
			ngx.say(value)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
4929610868617230
--- no_error_log
[error]

=== TEST 6: Return value types
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op  = require "resty.waf.operators"
			local waf = { _pcre_flags = 'oj' }

			local match, value = op.verify_cc(
				waf,
				'4929610868617230',
				[[^\d+$]]
			)

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

