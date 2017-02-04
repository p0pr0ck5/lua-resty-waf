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

=== TEST 1: No status nondisruptive action uses waf._deny_status
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":["values",1],"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()

			ngx.log(ngx.INFO, "We should not see this")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?a=foo
--- error_code: 403
--- error_log
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]
We should not see this

=== TEST 2: status nondisruptive action overrides waf._deny_status
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY","nondisrupt":[{"action":"status","data":404}]},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":["values",1],"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?a=foo
--- error_code: 404
--- error_log
Rule action was DENY, so telling nginx to quit
Overriding status from 403 to 404
--- no_error_log
[error]

=== TEST 3: ctx.rule_status is reset every rule
--- http_config eval: $::HttpConfig
--- config
	location /s {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10200", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":["values",1],"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}

	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY","nondisrupt":[{"action":"status","data":404}]},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":["values",1],"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request eval
["GET /t?a=foo", "GET /s?a=foo"]
--- error_code eval
[404, 403]
--- no_error_log
[error]

