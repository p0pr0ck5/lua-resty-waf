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

=== TEST 1: DENY exits the phase with ngx.HTTP_FORBIDDEN in custom phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"header_filter":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"parse":["values",1],"type":"RESPONSE_HEADERS"}]}],"body_filter":[],"access":[]}]=])
			waf:exec({
				phase = "header_filter",
				collections = {
					RESPONSE_HEADERS = { ["X-Foo"] = "bar" }
				}
			})

			ngx.log(ngx.INFO, "We should not see this")
		}
	}
--- request
GET /t
--- error_code: 403
--- error_log
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]
We should not see this
