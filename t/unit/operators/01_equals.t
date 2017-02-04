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

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local equals = require "resty.waf.operators"
        }
    }
--- request
    GET /t
--- response_body
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: integer equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals(1, 1)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: integer not equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals(1, 2)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: string equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: string not equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "bar")
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: integer table equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals({3, 2, 1}, 1)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: integer table not equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals({3, 2, 0}, 1)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: string table equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals({"bar", "foo"}, "foo")
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
true
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: string table not equals
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals({"bar", "baz"}, "foo")
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: string "nil" not equals nil
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("nil", nil)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 11: string not equals integer
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("7", 7)
			ngx.say(equals)
        }
    }
--- request
    GET /t
--- response_body
false
--- error_code: 200
--- no_error_log
[error]

=== TEST 12: return values
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(equals)
			ngx.say(value)
        }
    }
--- request
    GET /t
--- response_body
true
foo
--- error_code: 200
--- no_error_log
[error]

=== TEST 13: return value types
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local op = require "resty.waf.operators"
			local equals, value = op.equals("foo", "foo")
			ngx.say(type(equals))
			ngx.say(type(value))
        }
    }
--- request
    GET /t
--- response_body
boolean
string
--- error_code: 200
--- no_error_log
[error]

