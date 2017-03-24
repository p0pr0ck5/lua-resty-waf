use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 2 * blocks();

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Non digit Content-Length without content-type
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
--- more_headers
Content-Length: NotDigits
--- error_code: 400
--- no_error_log
[error]

=== TEST 2: Non digit Content-Length with content-type
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
--- more_headers
Content-Length: NotDigits
Content-Type: application/x-www-form-urlencoded
--- error_code: 400
--- no_error_log
[error]

=== TEST 3: Mixed digit and non digit content length
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
--- more_headers
Content-Length: 123x
Content-Type: application/x-www-form-urlencoded
--- error_code: 400
--- no_error_log
[error]

=== TEST 4: 920160 regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
foo
--- more_headers
Content-Length: '3'
--- error_code: 400
--- no_error_log
[error]

=== TEST 5: 920160 regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
foo
--- more_headers
Content-Length: "3;"
--- error_code: 400
--- no_error_log
[error]

