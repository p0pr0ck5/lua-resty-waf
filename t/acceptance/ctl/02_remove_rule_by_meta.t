use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ignore rules at runtime based on tag
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "10000_ctl_meta")

--[[
rules for these tests:

SecAction "id:12345,phase:1,pass,nolog,ctl:ruleRemoveByTag=mocktag"
SecAction "id:12355,phase:1,pass,nolog,ctl:ruleRemoveByMsg=mockmsg"

SecRule ARGS bar "id:12346,phase:1,deny,tag:'mocktag'"
SecRule ARGS baz "id:12347,phase:1,deny,tag:'mocktag',tag:'othertag'"
SecRule ARGS bat "id:12348,phase:1,deny,tag:'othertag'"

SecRule ARGS foo "id:12356,phase:1,deny,msg:'mockmsg'"
SecRule ARGS frob "id:12357,phase:1,deny,msg:'othermsg'"
--]]

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 200
--- error_log
Runtime ignoring rules by meta
Runtime ignoring rule 12346
Runtime ignoring rule 12347
Ignoring rule 12346
Ignoring rule 12347
--- no_error_log
[error]
Runtime ignoring rule 12348
Ignoring rule 12348

=== TEST 2: Matched rules not in an exception group still execute
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "10000_ctl_meta")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t?a=bat
--- error_code: 403
--- error_log
Match of rule 12348
--- no_error_log
[error]

=== TEST 3: Ignore a rule at runtime based on msg
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "10000_ctl_meta")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t
--- error_code: 200
--- error_log
Runtime ignoring rules by meta
Ignoring rule 12356
--- no_error_log
[error]
Ignoring rule 12357

=== TEST 4: Matched rules not in an exception group still execute
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "10000_ctl_meta")

			waf:exec()
		}

		content_by_lua_block { ngx.exit(ngx.HTTP_OK) }
	}
--- request
GET /t?a=frob
--- error_code: 403
--- error_log
Match of rule 12357
--- no_error_log
[error]

