use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ignore a rule at runtime
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "10000_ctl")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 200
--- error_log
Runtime ignoring rule 12346
Ignoring rule 12346
--- no_error_log
[error]

