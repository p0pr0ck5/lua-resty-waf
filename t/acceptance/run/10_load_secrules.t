use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 10 * blocks() - 3;

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Load a valid SecRules file
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/test.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "test.rules")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?a=foo
--- error_code: 403
--- error_log
Match of rule 12345
Beginning ruleset 11000_whitelist,
Beginning ruleset 20000_http_violation,
Beginning ruleset 21000_http_anomaly,
Beginning ruleset 35000_user_agent,
Beginning ruleset 40000_generic_attack,
Beginning ruleset 41000_sqli,
Beginning ruleset 42000_xss,
Beginning ruleset 90000_custom,
Beginning ruleset 99000_scoring,
Beginning ruleset test.rules,
--- no_error_log
[error]
Doing offset calculation

=== TEST 2: Error on loading a DNE SecRules file
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local ok, err = pcall(function()
			waf.load_secrules("$::pwd/t/rules/test.dne")
		end)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning ruleset 11000_whitelist,
Beginning ruleset 20000_http_violation,
Beginning ruleset 21000_http_anomaly,
Beginning ruleset 35000_user_agent,
Beginning ruleset 40000_generic_attack,
Beginning ruleset 41000_sqli,
Beginning ruleset 42000_xss,
Beginning ruleset 90000_custom,
Beginning ruleset 99000_scoring,
--- no_error_log
[error]
Beginning ruleset test.dne,
Doing offset calculation

=== TEST 3: Error on trying to use an unloaded ruleset
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local ok, err = pcall(function()
			waf.load_secrules("$::pwd/t/rules/test.dne")
		end)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "test.dne")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 500
--- error_log
could not find test.dne
--- no_error_log
