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

=== TEST 1: Append b with a few elements to an empty a
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local a = {}
			local b = { "foo", "bar" }

			util.table_append(a, b)

			ngx.say(table.concat(a, "\n"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
bar
--- no_error_log
[error]

=== TEST 2: Append b with a few elements to an existing a
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local a = { "baz", "bat" }
			local b = { "foo", "bar" }

			util.table_append(a, b)

			ngx.say(table.concat(a, "\n"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
baz
bat
foo
bar
--- no_error_log
[error]

=== TEST 3: Append b as a non-table to an empty a
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local a = {}
			local b = "foo"

			util.table_append(a, b)

			ngx.say(table.concat(a, "\n"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
foo
--- no_error_log
[error]

=== TEST 3: Append b as a non-table to an existing a
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local a = { "bat", "baz"}
			local b = "foo"

			util.table_append(a, b)

			ngx.say(table.concat(a, "\n"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
bat
baz
foo
--- no_error_log
[error]

