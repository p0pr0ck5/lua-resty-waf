use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: base64_decode
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "aGVsbG8gd29ybGQ="
			local transform = lookup.transform["base64_decode"]({}, value)
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
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "goodbye world"
			local transform = lookup.transform["base64_encode"]({}, value)
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

=== TEST 3: compress_whitespace
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "how  	are	you    doing?"
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

=== TEST 4: html_decode
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = [=[&quot;He said &apos;hi&apos; to &#40;&lt;him&gt; &amp; &lt;her&gt;&#41;&quot;]=]
			local transform = lookup.transform["html_decode"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
"He said 'hi' to (<him> & <her>)"
--- no_error_log
[error]

=== TEST 5: lowercase
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "HELLO WORLD"
			local transform = lookup.transform["lowercase"]({}, value)
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

=== TEST 6: remove_comments
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "UNI/*1*/ON SELECT"
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

=== TEST 7: remove_whitespace
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "how  	are	you    doing?"
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

=== TEST 8: replace_comments
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "UNION/***/SELECT"
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

=== TEST 9: uri_decode
--- config
	location /t {
		content_by_lua '
			local lookup = require "FreeWAF.lib.lookup"
			local value  = "%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E"
			local transform = lookup.transform["uri_decode"]({}, value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
"><script>alert(1)</script>
--- no_error_log
[error]

