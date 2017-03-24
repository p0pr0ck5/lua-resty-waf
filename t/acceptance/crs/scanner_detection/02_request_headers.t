use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: 913110 regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = { path = "$::pwd/rules/" }

		waf.load_secrules("$::pwd/rules/REQUEST-913-SCANNER-DETECTION.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-913-SCANNER-DETECTION.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- more_headers
Acunetix-Product: WVS/5.0 (Acunetix Web Vulnerability Scanner - EVALUATION)
--- error_code: 200
--- error_log
Match of rule 913110
--- no_error_log
[error]

=== TEST 2: 913110 regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = { path = "$::pwd/rules/" }

		waf.load_secrules("$::pwd/rules/REQUEST-913-SCANNER-DETECTION.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-913-SCANNER-DETECTION.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- more_headers
X-Scanner: whatever
--- error_code: 200
--- error_log
Match of rule 913110
--- no_error_log
[error]

