use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 14 * blocks() - 3;

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Runs the default rulesets
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
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
Beginning ruleset extra,
Adding ruleset
Ignoring ruleset

=== TEST 2: Ignore a ruleset
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("ignore_ruleset", "90000_custom")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Ignoring ruleset 90000_custom,
Beginning ruleset 11000_whitelist,
Beginning ruleset 20000_http_violation,
Beginning ruleset 21000_http_anomaly,
Beginning ruleset 35000_user_agent,
Beginning ruleset 40000_generic_attack,
Beginning ruleset 41000_sqli,
Beginning ruleset 42000_xss,
Beginning ruleset 99000_scoring,
--- no_error_log
[error]
Beginning ruleset extra,
Beginning ruleset 90000_custom,
Adding ruleset

=== TEST 3: Add a custom ruleset
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "extra")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
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
Beginning ruleset 99000_scoring,
Adding ruleset extra
Beginning ruleset extra,
--- no_error_log
[error]
Ignoring ruleset
