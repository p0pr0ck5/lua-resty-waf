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

=== TEST 1: No User-Agent
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
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 913100

=== TEST 2: 913100 regression
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
User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727) Havij
--- error_code: 200
--- error_log
Match of rule 913100
--- no_error_log
[error]

=== TEST 3: 913100 regression
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
User-Agent: Arachni/0.2.1
--- error_code: 200
--- error_log
Match of rule 913100
--- no_error_log
[error]

=== TEST 4: 913100 regression
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
User-Agent: w3af.sourceforge.net
--- error_code: 200
--- error_log
Match of rule 913100
--- no_error_log
[error]

=== TEST 5: 913100 regression
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
User-Agent: nessus
--- error_code: 200
--- error_log
Match of rule 913100
--- no_error_log
[error]

