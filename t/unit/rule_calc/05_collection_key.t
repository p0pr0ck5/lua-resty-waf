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

=== TEST 1: No parse, no transform, no length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO" } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|nil
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Truthy key, no transform, no length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", parse = { "keys", 1 } } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|keys|1|nil
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: String key, no transform, no length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", parse = { "specific", "bar" } } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|specific|bar|nil
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: No parse, single transform, no length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO" } }, opts = { transform = "bar" }, actions = { disrupt = "DENY" }  },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|bar
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: No parse, multiple transforms, no length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO" } }, opts = { transform = { "bar", "bat" } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|bar,bat
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: No parse, no transform, length
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", length = 1 } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|nil
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: No parse, no transform, ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", ignore = { {"ignore", "foo" } } } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|ignore,foo|nil
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: No parse, transform, ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", ignore = { { "ignore", "foo" } } } }, opts = { transform = "bar" }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|ignore,foo|bar
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: Parse, transform, ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", parse = { "specific", "bar" }, ignore = { { "ignore", "foo" } } } }, opts = { transform = "bar" }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|specific|bar|ignore,foo|bar
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: No parse, no transform, multiple ignores
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = { { type = "FOO", ignore = { { "ignore", "foo" }, { "regex", "^bar" } } } }, actions = { disrupt = "DENY" } },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].vars[1].collection_key)
		';
	}
--- request
GET /t
--- response_body
FOO|ignore,foo,regex,^bar|nil
--- error_code: 200
--- no_error_log
[error]

