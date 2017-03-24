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

=== TEST 1: 913120 regression
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
	location /n {
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
GET /nessustest
--- error_code: 200
--- error_log
Match of rule 913120
--- no_error_log
[error]

=== TEST 2: IBM fingerprint from (http://www-01.ibm.com/support/docview.wss?uid=swg21293132)
--- ONLY
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
	location /A {
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
GET /AppScan_fingerprint/MAC_ADDRESS_01234567890.html?9ABCDG1
--- error_code: 200
--- error_log
Match of rule 913120
--- no_error_log
[error]

=== TEST 3: Scanner identification based on uri
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
	location /n {
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
GET /nessus_is_probing_you_
--- error_code: 200
--- error_log
Match of rule 913120
--- no_error_log
[error]

