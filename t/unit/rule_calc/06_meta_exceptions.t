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

=== TEST 1: Build meta exceptions table with msgs
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"

			local meta_lookup = { msgs = {}, tags = {} }

			local mock_rules = {
				{
					id = 1,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "foo"
				},
				{
					id = 2,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "foo"
				},
				{
					id = 3,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "bar"
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			ngx.say(table.concat(meta_lookup.msgs["foo"], ", "))
			ngx.say(table.concat(meta_lookup.msgs["bar"], ", "))
		}
	}
--- request
GET /t
--- response_body
1, 2
3
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Build meta exceptions table with msgs, multiple rulesets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"

			local meta_lookup = { msgs = {}, tags = {} }

			local mock_rules = {
				{
					id = 1,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "foo"
				},
				{
					id = 2,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "foo"
				},
				{
					id = 3,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "bar"
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			mock_rules = {
				{
					id = 4,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "foo"
				},
				{
					id = 5,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "baz"
				},
				{
					id = 6,
					vars = {},
					actions = { disrupt = "DENY" },
					msg = "bat"
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			ngx.say(table.concat(meta_lookup.msgs["foo"], ", "))
			ngx.say(table.concat(meta_lookup.msgs["bar"], ", "))
			ngx.say(table.concat(meta_lookup.msgs["baz"], ", "))
			ngx.say(table.concat(meta_lookup.msgs["bat"], ", "))
		}
	}
--- request
GET /t
--- response_body
1, 2, 4
3
5
6
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Build meta exceptions table with tags
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"

			local meta_lookup = { msgs = {}, tags = {} }

			local mock_rules = {
				{
					id = 1,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"foo",
						"bar"
					}
				},
				{
					id = 2,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"foo",
						"baz"
					}
				},
				{
					id = 3,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"baz",
						"bat"
					}
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			ngx.say(table.concat(meta_lookup.tags["foo"], ", "))
			ngx.say(table.concat(meta_lookup.tags["bar"], ", "))
			ngx.say(table.concat(meta_lookup.tags["baz"], ", "))
			ngx.say(table.concat(meta_lookup.tags["bat"], ", "))
		}
	}
--- request
GET /t
--- response_body
1, 2
1
2, 3
3
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: Build meta exceptions table with tags, multiple rulesets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local rule_calc  = require "resty.waf.rule_calc"

			local meta_lookup = { msgs = {}, tags = {} }

			local mock_rules = {
				{
					id = 1,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"foo",
						"bar"
					}
				},
				{
					id = 2,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"foo",
						"baz"
					}
				},
				{
					id = 3,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"baz",
						"bat"
					}
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			mock_rules = {
				{
					id = 4,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"foo",
						"bar",
						"baz",
						"bat"
					}
				},
				{
					id = 5,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"bat",
						"baz"
					}
				},
				{
					id = 6,
					vars = {},
					actions = { disrupt = "DENY" },
					tag = {
						"baz",
						"bat",
						"bar"
					}
				},
			}

			rule_calc.calculate(mock_rules, meta_lookup)

			ngx.say(table.concat(meta_lookup.tags["foo"], ", "))
			ngx.say(table.concat(meta_lookup.tags["bar"], ", "))
			ngx.say(table.concat(meta_lookup.tags["baz"], ", "))
			ngx.say(table.concat(meta_lookup.tags["bat"], ", "))
		}
	}
--- request
GET /t
--- response_body
1, 2, 4
1, 4, 6
2, 3, 4, 5, 6
3, 4, 5, 6
--- error_code: 200
--- no_error_log
[error]

