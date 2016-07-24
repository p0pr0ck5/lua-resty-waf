use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: compress_whitespace
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "how  	are	you    doing?"
			local transform = lookup.transform["compress_whitespace"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
how are you doing?
--- no_error_log
[error]

=== TEST 2: remove_whitespace
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.lookup"
			local value     = "how  	are	you    doing?"
			local transform = lookup.transform["remove_whitespace"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
howareyoudoing?
--- no_error_log
[error]

