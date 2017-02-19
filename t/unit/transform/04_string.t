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

=== TEST 1: lowercase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "HELLO WORLD"
			local transform = lookup.lookup["lowercase"]({}, value)
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

=== TEST 2: string length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "hello world"
			local transform = lookup.lookup["length"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
11
--- no_error_log
[error]

=== TEST 3: string length (number)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = 8001
			local transform = lookup.lookup["length"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
4
--- no_error_log
[error]

=== TEST 4: string length (boolean)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = true
			local transform = lookup.lookup["length"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
4
--- no_error_log
[error]

