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

=== TEST 1: Build the lookup table though string matches
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local exception_table = {
				msgs = {
					foo = { 1, 2, 3 },
					bar = { 4, 5, 6 },
				},
				tags = {
					baz = { 1, 2, 3 },
					bat = { 4, 5, 6 },
				},
				meta_ids = {}
			}

			local rule = {
				id = 12345,
				exceptions = { "foo", "bar" }
			}

			util.rule_exception(exception_table, rule)

			ngx.say(table.concat(exception_table.meta_ids[12345], ", "))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
1, 2, 3, 4, 5, 6
--- no_error_log
[error]

=== TEST 2: Build the lookup table though regex (some duplicates)`
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local exception_table = {
				msgs = {
					foo = { 1, 2, 3 },
					bar = { 4, 5, 6 },
				},
				tags = {
					baz = { 1, 2, 3 },
					bat = { 4, 5, 6 },
				},
				meta_ids = {}
			}

			local rule = {
				id = 12345,
				exceptions = { "^b" }
			}

			util.rule_exception(exception_table, rule)

			ngx.say(table.concat(exception_table.meta_ids[12345], ", "))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
4, 5, 6, 4, 5, 6, 1, 2, 3
--- no_error_log
[error]

=== TEST 3: Do nothing if the rule has no exceptions
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
			local util = require "resty.waf.util"

			local exception_table = {
				msgs = {
					foo = { 1, 2, 3 },
					bar = { 4, 5, 6 },
				},
				tags = {
					baz = { 1, 2, 3 },
					bat = { 4, 5, 6 },
				},
				meta_ids = {}
			}

			local rule = {
				id = 12345
			}

			util.rule_exception(exception_table, rule)

			ngx.say(type(exception_table.meta_ids[12345]))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

