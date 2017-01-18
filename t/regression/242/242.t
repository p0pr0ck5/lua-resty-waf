use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks() - 6;

check_accum_error_log();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ignore specific 'foo' and regex '^b' (not found)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "12345", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"ignore":[["ignore","foo"],["regex","^b"]],"parse":["values","1"],"type":"URI_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?a=bar
--- error_code: 403
--- error_log
Sieveing specific value foo
Sieveing regex value ^b
--- no_error_log
[error]

=== TEST 2: Ignore specific 'foo' and regex '^b' (specific found)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "12345", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"ignore":[["ignore","foo"],["regex","^b"]],"parse":["values","1"],"type":"URI_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?foo=bar
--- error_code: 200
--- error_log
Sieveing specific value foo
Sieveing regex value ^b
--- no_error_log
[error]

=== TEST 3: Ignore specific 'foo' and regex '^b' (regex found)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "12345", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"ignore":[["ignore","foo"],["regex","^b"]],"parse":["values","1"],"type":"URI_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?bat=bar
--- error_code: 200
--- error_log
Sieveing specific value foo
Sieveing regex value ^b
Removing bat
--- no_error_log
[error]

=== TEST 4: Ignore specific 'foo' and regex '^b' (found with other param)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "12345", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"ignore":[["ignore","foo"],["regex","^b"]],"parse":["values","1"],"type":"URI_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?a=bar&foo=bar
--- error_code: 403
--- error_log
Sieveing specific value foo
Sieveing regex value ^b
--- no_error_log
[error]


=== TEST 5: Ignore handled in one rule doesn't reflect on another rule (same collection)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "12345", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"ignore":[["ignore","foo"],["regex","^b"]],"parse":["values","1"],"type":"URI_ARGS"}]},{"actions":{"disrupt":"DENY"},"id":"12346","operator":"REGEX","pattern":"bar","vars":[{"parse":["values","1"],"type":"URI_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t?foo=bar
--- error_code: 403
--- error_log
Sieveing specific value foo
Sieveing regex value ^b
Match of rule 12346
--- no_error_log
[error]
Match of rule 12345
