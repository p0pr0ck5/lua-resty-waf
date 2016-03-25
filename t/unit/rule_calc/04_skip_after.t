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
				{ id = 2, vars = {}, action = "IGNORE", skip_after = 3 },
				{ id = 3, vars = {}, action = "DENY" },
				{ id = 4, vars = {}, action = "DENY" },
				{ id = 5, vars = {}, action = "DENY" },
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

=== TEST 2: Skip after next rule offsets
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "IGNORE", skip_after = 3 },
				{ id = 3, vars = {}, action = "DENY" },
				{ id = 4, vars = {}, action = "DENY" },
				{ id = 5, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
2
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Skip after two rules offsets
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "SKIP", skip_after = 4 },
				{ id = 3, vars = {}, action = "DENY" },
				{ id = 4, vars = {}, action = "DENY" },
				{ id = 5, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
3
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: Skip after end of ruleset
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "IGNORE", skip_after = 5 },
				{ id = 3, vars = {}, action = "DENY" },
				{ id = 4, vars = {}, action = "DENY" },
				{ id = 5, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[2].offset_match)
			ngx.say(mock_rules[2].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
nil
1
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: Skip after chain starter
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "CHAIN" },
				{ id = 3, vars = {}, action = "CHAIN" },
				{ id = 4, vars = {}, action = "IGNORE", skip_after = 5 },
				{ id = 5, vars = {}, action = "DENY" },
				{ id = 6, vars = {}, action = "DENY" },
				{ id = 7, vars = {}, action = "DENY" },
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
3
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: Skip after chain middle
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "CHAIN" },
				{ id = 3, vars = {}, action = "CHAIN" },
				{ id = 4, vars = {}, action = "IGNORE", skip_after = 5 },
				{ id = 5, vars = {}, action = "DENY" },
				{ id = 6, vars = {}, action = "DENY" },
				{ id = 7, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[3].offset_match)
			ngx.say(mock_rules[3].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
1
2
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: Skip after chain end
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "lib.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, action = "DENY" },
				{ id = 2, vars = {}, action = "CHAIN" },
				{ id = 3, vars = {}, action = "CHAIN" },
				{ id = 4, vars = {}, action = "IGNORE", skip_after = 5 },
				{ id = 5, vars = {}, action = "DENY" },
				{ id = 6, vars = {}, action = "DENY" },
				{ id = 7, vars = {}, action = "DENY" },
			}

			rule_calc.calculate(mock_rules)

			ngx.say(mock_rules[4].offset_match)
			ngx.say(mock_rules[4].offset_nomatch)
		';
	}
--- request
GET /t
--- response_body
2
1
--- error_code: 200
--- no_error_log
[error]

