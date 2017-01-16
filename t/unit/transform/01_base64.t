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

=== TEST 1: base64_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "aGVsbG8gd29ybGQ="
			local transform = lookup.lookup["base64_decode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello world
--- no_error_log
[error]

=== TEST 2: base64_encode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "goodbye world"
			local transform = lookup.lookup["base64_encode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
Z29vZGJ5ZSB3b3JsZA==
--- no_error_log
[error]

