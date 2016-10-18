use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks();

check_accum_error_log();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Add an inline ruleset via set_option
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":73,"operator":"REGEX","opts":{},"pattern":"foo","vars":[{"parse":{"values":1},"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Adding ruleset string 10100
Beginning ruleset 10100,
Processing rule 73
--- no_error_log
[error]

=== TEST 2: Add an inline ruleset via set_option, then ignore a rule in the ruleset
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset_string", "10100", [=[{"access":[{"actions":{"disrupt":"DENY"},"id":73,"operator":"REGEX","opts":{},"pattern":"foo","vars":[{"parse":{"values":1},"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
			waf:set_option("ignore_rule", 73)

			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Adding ruleset string 10100
Beginning ruleset 10100,
--- no_error_log
[error]
Processing rule 73

