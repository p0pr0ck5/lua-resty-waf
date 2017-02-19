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

=== TEST 1: html_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[&quot;He said &apos;hi&apos; to &#40;&lt;him&gt; &amp; &lt;her&gt;&#41;&quot;]]
			local transform = lookup.lookup["html_decode"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
"He said 'hi' to (<him> & <her>)"
--- no_error_log
[error]

=== TEST 2: uri_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E"
			local transform = lookup.lookup["uri_decode"]({}, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
"><script>alert(1)</script>
--- no_error_log
[error]

=== TEST 3: normalise_path (duplicate slashes)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "/a//b///c"
			local transform = lookup.lookup["normalise_path"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
/a/b/c
--- no_error_log
[error]

=== TEST 4: normalise_path (self reference)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "/a/b/./c"
			local transform = lookup.lookup["normalise_path"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
/a/b/c
--- no_error_log
[error]

=== TEST 5: normalise_path (back reference)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "/a/d/../b/c"
			local transform = lookup.lookup["normalise_path"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
/a/b/c
--- no_error_log
[error]

=== TEST 6: normalise_path (mulitple normalizations)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = "/a///b/d/../c/./e/../"
			local transform = lookup.lookup["normalise_path"]({ _pcre_flags = "" }, value)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
/a/b/c/
--- no_error_log
[error]

