use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ruleset starter offsets
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "DENY" },
				{ id = 3, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[1].offset_match)
			ngx.say(mock_rules[1].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
1
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: Ruleset middle element offsets
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "DENY" },
				{ id = 3, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
1
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Ruleset end offsets
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "DENY" },
				{ id = 3, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[3].offset_match)
			ngx.say(mock_rules[3].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
nil
nil
--- error_code: 200
--- no_error_log
[error]

