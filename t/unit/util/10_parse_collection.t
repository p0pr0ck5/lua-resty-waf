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

=== TEST 1: Specific (individual)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["specific"]({}, collection, "foo")
			ngx.say(specific)
		}
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: Specific (table)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["specific"]({}, collection, "foo")
			for i in ipairs(specific) do
				ngx.say(specific[i])
			end
		}
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
bar
bat
--- no_error_log
[error]

=== TEST 3: Keys (individual)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local keys       = lookup.parse_collection["keys"]({}, collection, "foo")
			for i in ipairs(keys) do
				ngx.say(keys[i])
			end
		}
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
foo
baz
--- no_error_log
[error]

=== TEST 4: Keys (table)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local keys       = lookup.parse_collection["keys"]({}, collection, "foo")
			for i in ipairs(keys) do
				ngx.say(keys[i])
			end
		}
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
foo
baz
--- no_error_log
[error]

=== TEST 5: Values (individual)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local values     = lookup.parse_collection["values"]({}, collection, "foo")
			for i in ipairs(values) do
				ngx.say(values[i])
			end
		}
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
bar
qux
--- no_error_log
[error]

=== TEST 6: Values (table)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local values     = lookup.parse_collection["values"]({}, collection, "foo")
			for i in ipairs(values) do
				ngx.say(values[i])
			end
		}
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
bar
bat
qux
--- no_error_log
[error]

=== TEST 7: All (individual)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local all        = lookup.parse_collection["all"]({}, collection, "foo")
			for i in ipairs(all) do
				ngx.say(all[i])
			end
		}
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
foo
baz
bar
qux
--- no_error_log
[error]

=== TEST 8: All (table)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local all        = lookup.parse_collection["all"]({}, collection, "foo")
			for i in ipairs(all) do
				ngx.say(all[i])
			end
		}
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
foo
baz
bar
bat
qux
--- no_error_log
[error]

=== TEST 9: Regex (individual)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["regex"]({ _pcre_flags = "joi" }, collection, [=[^f]=])
			ngx.say(specific)
		}
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 10: Regex (table)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lookup     = require "resty.waf.util"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["regex"]({ _pcre_flags = "joi" }, collection, [=[^f]=])
			for i in ipairs(specific) do
				ngx.say(specific[i])
			end
		}
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
bar
bat
--- no_error_log
[error]
