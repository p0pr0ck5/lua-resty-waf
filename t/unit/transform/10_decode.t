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

=== TEST 1: js_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[hello \u0022world\u005C\u0026]]
			local transform = lookup.lookup["js_decode"](
				{ _pcre_flags = "" },
				value
			)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello "world\&
--- no_error_log
[error]

=== TEST 2: js_decode (no alterations)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[hello "world\\&]]
			local transform = lookup.lookup["js_decode"](
				{ _pcre_flags = "" },
				value
			)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello "world\&
--- no_error_log
[error]

=== TEST 3: css_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[hello \0022world\005C\0026]]
			local transform = lookup.lookup["css_decode"](
				{ _pcre_flags = "" },
				value
			)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello "world\&
--- no_error_log
[error]

=== TEST 4: css_decode (no alterations)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[hello "world\\&]]
			local transform = lookup.lookup["css_decode"](
				{ _pcre_flags = "" },
				value
			)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello "world\&
--- no_error_log
[error]

=== TEST 4: css_decode (modsec example)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup    = require "resty.waf.transform"
			local value     = [[ja\vascript]]
			local transform = lookup.lookup["css_decode"](
				{ _pcre_flags = "" },
				value
			)
			ngx.say(transform)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
javascript
--- no_error_log
[error]

