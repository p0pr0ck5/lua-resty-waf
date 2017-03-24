use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: POST Request with data (valid)
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
hi=test
--- error_code: 200
--- no_error_log
[error]
Match of rule 920170
Setting TX:920170

=== TEST 2: GET Request with data
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
GET /t
hi=test
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
Match of rule 920170
Setting TX:920170
--- no_error_log
[error]

=== TEST 3: HEAD Request with data
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
HEAD /t
hi=test
--- error_code: 200
--- error_log
Match of rule 920170
Setting TX:920170
--- no_error_log
[error]

=== TEST 4: GET Request with data (0 Content-Length)
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
GET /t
hi=test
--- more_headers
Content-Length: 0
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
Match of rule 920170
--- no_error_log
[error]
Setting TX:920170

=== TEST 5: GET Request with no data
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
GET /t
--- error_code: 200
--- error_log
Match of rule 920170
--- no_error_log
[error]
Setting TX:920170

=== TEST 6: GET Request with data (legacy regression)
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
GET /t
abc
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
Match of rule 920170
Setting TX:920170
--- no_error_log
[error]

