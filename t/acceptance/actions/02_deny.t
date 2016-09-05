use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: DENY exits the phase with ngx.HTTP_FORBIDDEN
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":{"values":1},"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()

			ngx.log(ngx.INFO, "We should not see this")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?a=foo
--- error_code: 403
--- error_log
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]
We should not see this

=== TEST 2: DENY does not exit the phase when mode is not ACTIVE
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"foo","vars":[{"parse":{"values":1},"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()

			ngx.log(ngx.INFO, "We should see this")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?a=foo
--- error_code: 200
--- error_log
Rule action was DENY, so telling nginx to quit
We should see this
--- no_error_log
[error]

