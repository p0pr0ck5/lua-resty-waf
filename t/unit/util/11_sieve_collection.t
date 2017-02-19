use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 7 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Individual ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util = require "resty.waf.util"

			local collection = {
				foo = "foo",
				bar = "bar",
				baz = "baz",
			}

			util.sieve_collection["ignore"]({_debug = true, _debug_log_level = ngx.INFO}, collection, "bar")
			ngx.say(tostring(collection.foo))
			ngx.say(tostring(collection.bar))
			ngx.say(tostring(collection.baz))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
nil
baz
--- error_log
Sieveing specific value bar
--- no_error_log
[error]

=== TEST 2: Multiple ignores
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util = require "resty.waf.util"

			local collection = {
				foo = "foo",
				bar = "bar",
				baz = "baz",
			}

			util.sieve_collection["ignore"]({_debug = true, _debug_log_level = ngx.INFO}, collection, "bar")
			util.sieve_collection["ignore"]({_debug = true, _debug_log_level = ngx.INFO}, collection, "baz")
			ngx.say(tostring(collection.foo))
			ngx.say(tostring(collection.bar))
			ngx.say(tostring(collection.baz))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
nil
nil
--- error_log
Sieveing specific value bar
Sieveing specific value baz
--- no_error_log
[error]

=== TEST 3: Ignore non-existent element
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util = require "resty.waf.util"

			local collection = {
				foo = "foo",
				bar = "bar",
				baz = "baz",
			}

			util.sieve_collection["ignore"]({_debug = true, _debug_log_level = ngx.INFO}, collection, "qux")
			ngx.say(tostring(collection.foo))
			ngx.say(tostring(collection.bar))
			ngx.say(tostring(collection.baz))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
bar
baz
--- error_log
Sieveing specific value qux
--- no_error_log
[error]

=== TEST 4: Regex single element
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util = require "resty.waf.util"

			local collection = {
				foo = "foo",
				bar = "bar",
				baz = "baz",
			}

			util.sieve_collection["regex"]({_debug = true, _debug_log_level = ngx.INFO, _pcre_flags = ""}, collection, "^f")
			ngx.say(tostring(collection.foo))
			ngx.say(tostring(collection.bar))
			ngx.say(tostring(collection.baz))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
bar
baz
--- error_log
Sieveing regex value ^f
Checking foo
Removing foo
Checking bar
Checking baz
--- no_error_log
[error]
Removing bar
Removing baz

=== TEST 5: Ignore and regex
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local util = require "resty.waf.util"

			local collection = {
				foo = "foo",
				bar = "bar",
				baz = "baz",
			}

			util.sieve_collection["ignore"]({_debug = true, _debug_log_level = ngx.INFO}, collection, "bar")
			util.sieve_collection["regex"]({_debug = true, _debug_log_level = ngx.INFO, _pcre_flags = ""}, collection, "^f")
			ngx.say(tostring(collection.foo))
			ngx.say(tostring(collection.bar))
			ngx.say(tostring(collection.baz))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
nil
baz
--- error_log
Sieveing specific value bar
Sieveing regex value ^f
Checking foo
Removing foo
Checking baz
--- no_error_log
[error]
Checking bar
Removing bar
Removing baz
