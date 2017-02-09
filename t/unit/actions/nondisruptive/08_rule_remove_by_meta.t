use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: rule_remove_by_meta adds to waf._ignore_rule
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local actions = require "resty.waf.actions"

			local meta_exception = {
				meta_ids = {}
			}

			meta_exception.meta_ids[12345] = { 1, 2, 3 }

			local waf = { _debug = true, _debug_log_level = ngx.INFO,
				_ignore_rule = {}, _meta_exception = meta_exception }

			actions.nondisruptive_lookup["rule_remove_by_meta"](
				waf,
				nil,
				{ id = 12345 }
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
1
2
3
--- error_log
Runtime ignoring rules by meta
--- no_error_log
[error]

=== TEST 2: rule_remove_by_meta adds to waf._ignore_rule with config-time ignore
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local actions = require "resty.waf.actions"

			local meta_exception = {
				meta_ids = {}
			}

			meta_exception.meta_ids[12345] = { 1, 2, 3 }

			local waf = { _debug = true, _debug_log_level = ngx.INFO,
				_ignore_rule = { [12344] = true }, _meta_exception = meta_exception }

			actions.nondisruptive_lookup["rule_remove_by_meta"](
				waf,
				nil,
				{ id = 12345 }
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
1
2
3
12344
--- error_log
Runtime ignoring rules by meta
Runtime ignoring rule 1
Runtime ignoring rule 2
Runtime ignoring rule 3
--- no_error_log
[error]

