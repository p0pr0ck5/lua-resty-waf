use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: html_decode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = [[&quot;He said &apos;hi&apos; to &#40;&lt;him&gt; &amp; &lt;her&gt;&#41;&quot;]]
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

=== TEST 2: uri_decode
--- config
	location /t {
		content_by_lua '
			local lookup    = require "lib.lookup"
			local value     = "%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E"
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

