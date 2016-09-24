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

=== TEST 1: Delete all backslashes
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello \\ wor\\l\\\\d]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello \ wor\l\\d
hello world
--- no_error_log
[error]

=== TEST 2: Delete all double quotes
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello " wor"l""d]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello " wor"l""d
hello world
--- no_error_log
[error]

=== TEST 3: Delete all single quotes
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello \' wor\'l\'\'d]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello ' wor'l''d
hello world
--- no_error_log
[error]

=== TEST 4: Delete all carets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello ^ wor^l^^d]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello ^ wor^l^^d
hello world
--- no_error_log
[error]

=== TEST 5: All characters that should be deleted
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[\'hello \\ wor"l^d\']=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
'hello \ wor"l^d'
hello world
--- no_error_log
[error]

=== TEST 6: Delete spaces before a slash
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello /wo   /rld]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello /wo   /rld
hello/wo/rld
--- no_error_log
[error]

=== TEST 7: Delete spaces before an open parenthesis
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello (wo   (rld]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello (wo   (rld
hello(wo(rld
--- no_error_log
[error]

=== TEST 8: Replace all commas with a space
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello,world]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello,world
hello world
--- no_error_log
[error]

=== TEST 9: Replace all semicolons with a space
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello;world]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello;world
hello world
--- no_error_log
[error]

=== TEST 10: Replace all commas and semicolons with a space
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[hello,wo;rld]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
hello,wo;rld
hello wo rld
--- no_error_log
[error]

=== TEST 11: Compress whitespace
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[how      are you    doing]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
how      are you    doing
how are you doing
--- no_error_log
[error]

=== TEST 12: Lowercase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[HeLLo wORlD]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
HeLLo wORlD
hello world
--- no_error_log
[error]

=== TEST 13: Everything
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local lookup    = require "resty.waf.transform"
			local value     = [=[ThIs    IS th\\e	s^\'on"g th,At  / never ( ends;]=]
			local transform = lookup.lookup["cmd_line"]({ _pcre_flags = "oij" }, value)
			ngx.say(value)
			ngx.say(transform)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
ThIs    IS th\e	s^'on"g th,At  / never ( ends;
this is the song th at/ never( ends 
--- no_error_log
[error]

