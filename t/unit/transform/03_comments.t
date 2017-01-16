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

=== TEST 1: remove_comments
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "UNI/*1*/ON SELECT"
			local transform = lookup.lookup["remove_comments"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
UNION SELECT
--- no_error_log
[error]

=== TEST 2: remove_comments_char (c-style comments)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "UNION/* */SELECT"
			local transform = lookup.lookup["remove_comments_char"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
UNION SELECT
--- no_error_log
[error]

=== TEST 3: remove_comments_char (mysql dash comments)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "; DROP TABLE bobby--"
			local transform = lookup.lookup["remove_comments_char"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
; DROP TABLE bobby
--- no_error_log
[error]

=== TEST 4: remove_comments_char (octothorpe comments)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "; DROP TABLE bobby#"
			local transform = lookup.lookup["remove_comments_char"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
; DROP TABLE bobby
--- no_error_log
[error]

=== TEST 5: replace_comments
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = "UNION/***/SELECT"
			local transform = lookup.lookup["replace_comments"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
UNION SELECT
--- no_error_log
[error]

