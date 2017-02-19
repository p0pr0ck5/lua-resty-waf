use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: rule_remove_id adds to waf._ignore_rule
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local actions = require "resty.waf.actions"

			local waf = { _debug = true, _debug_log_level = ngx.INFO, _ignore_rule = {} }

			actions.nondisruptive_lookup["rule_remove_id"](
				waf,
				12345
			)

			for k, v in pairs(waf._ignore_rule) do
				ngx.say(k)
			end
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
12345
--- error_log
Runtime ignoring rule 12345
--- no_error_log
[error]

=== TEST 2: rule_remove_id adds to waf._ignore_rule with config-time ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local actions = require "resty.waf.actions"

			local waf = { _debug = true, _debug_log_level = ngx.INFO, _ignore_rule = { [12344] = true } }

			actions.nondisruptive_lookup["rule_remove_id"](
				waf,
				12345
			)

			for k, v in pairs(waf._ignore_rule) do
				ngx.say(k)
			end
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
12345
12344
--- error_log
Runtime ignoring rule 12345
--- no_error_log
[error]

