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

=== TEST 1: DENY based on a rule from a simple custom var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"parse":["specific","FOO"],"type":"TX"}]}],"body_filter":[],"header_filter":[]}]=])

			waf:set_var("FOO", "bar")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 403
--- error_log
Match of rule 12345
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]

=== TEST 2: DENY based on a rule from a dynamic custom var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12346","operator":"EQUALS","pattern":"127.0.0.1","vars":[{"parse":["specific","FOO"],"type":"TX"}]}],"body_filter":[],"header_filter":[]}]=])

			waf:set_var("FOO", "%{REMOTE_ADDR}")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 403
--- error_log
Match of rule 12346
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]

=== TEST 3: DENY based on a rule from a dynamic custom var with a specific element
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12347","operator":"REGEX","pattern":"bar","vars":[{"parse":["specific","FOO"],"type":"TX"}]}],"body_filter":[],"header_filter":[]}]=])

			waf:set_var("FOO", "%{REQUEST_HEADERS.X-Foo}")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- more_headers
X-Foo: bar
--- error_code: 403
--- error_log
Match of rule 12347
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]

