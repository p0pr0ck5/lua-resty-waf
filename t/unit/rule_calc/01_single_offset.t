use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ruleset starter offsets
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
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
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
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
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local rule_calc  = require "resty.waf.rule_calc"
			local mock_rules = {
				{ id = 1, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 2, vars = {}, actions = { disrupt = "DENY" }  },
				{ id = 3, vars = {}, actions = { disrupt = "DENY" }  },
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

