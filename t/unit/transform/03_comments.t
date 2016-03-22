use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: remove_comments
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "UNI/*1*/ON SELECT"
			local transform = lookup.transform["remove_comments"]({ _pcre_flags = "" }, value)
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
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "UNION/* */SELECT"
			local transform = lookup.transform["remove_comments_char"]({ _pcre_flags = "" }, value)
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
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "; DROP TABLE bobby--"
			local transform = lookup.transform["remove_comments_char"]({ _pcre_flags = "" }, value)
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
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "; DROP TABLE bobby#"
			local transform = lookup.transform["remove_comments_char"]({ _pcre_flags = "" }, value)
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
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "UNION/***/SELECT"
			local transform = lookup.transform["replace_comments"]({ _pcre_flags = "" }, value)
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

