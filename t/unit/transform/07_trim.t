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

=== TEST 1: trim
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "  hello world   "
			local transform = lookup.lookup["trim"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

=== TEST 2: trim (no change)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "hello world"
			local transform = lookup.lookup["trim"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

=== TEST 3: trim_left
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "  hello world"
			local transform = lookup.lookup["trim_left"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

=== TEST 4: trim_left (right whitespace untrimmed)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "  hello world   "
			local transform = lookup.lookup["trim_left"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world   
--- no_error_log
[error]

=== TEST 5: trim_right
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "hello world   "
			local transform = lookup.lookup["trim_right"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

=== TEST 6: trim_right (left whitespace untrimmed)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "  hello world   "
			local transform = lookup.lookup["trim_right"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
  hello world
--- no_error_log
[error]

