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

=== TEST 2: replace_comments
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

