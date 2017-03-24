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

=== TEST 1: Overwrite (add method, existing allowed)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD OPTIONS POST DELETE")

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

=== TEST 2: Overwrite (add method, new allowed)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD OPTIONS POST DELETE")

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
--- no_error_log
[error]
Match of rule 911100

=== TEST 3: Overwrite (add method, rule match)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD OPTIONS POST DELETE")

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
PATCH /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

=== TEST 4: Overwrite (remove method, existing allowed)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD POST")

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

=== TEST 5: Overwrite (remove method, new disallowed)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD POST")

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
Match of rule 911100
--- no_error_log
[error]

=== TEST 6: Overwrite (remove method, existing disallowed)
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

			waf:set_var("ALLOWED_METHODS", "GET HEAD POST")

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-911-METHOD-ENFORCEMENT.conf")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
PATCH /t
--- error_code: 200
--- error_log
Match of rule 911100
--- no_error_log
[error]

