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

=== TEST 1: GET
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
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
Match of rule 911100

=== TEST 2: HEAD
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
HEAD /t
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 911100

=== TEST 3: OPTIONS
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
OPTIONS /t
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 911100

=== TEST 4: POST
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
POST /t
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 911100

=== TEST 5: TEST
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
TEST /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

=== TEST 6: DELETE
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
DELETE /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

=== TEST 7: FOO
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
FOO /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

=== TEST 8: SUBSCRIBE
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/rules/REQUEST-911-METHOD-ENFORCEMENT.conf")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
SUBSCRIBE /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

