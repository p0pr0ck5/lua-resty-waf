use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Merge done in init
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 2: One-time global merge
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.default_option("ignore_ruleset", "42000_xss")

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 3: No global merge done (init never called)
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 4: Individual merge needed (scope-local ruleset change)
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
			waf:set_option("ignore_ruleset", "42000_xss")
			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
true
--- no_error_log
[error]

=== TEST 5: Ignoring ruleset triggers merge
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
			waf:set_option("ignore_ruleset", "42000_xss")
			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
true
--- no_error_log
[error]

=== TEST 6: Adding ruleset triggers merge
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
			waf:set_option("add_ruleset", "extra")
			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
true
--- no_error_log
[error]

=== TEST 7: Adding ruleset string triggers merge
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
			waf:set_option("add_ruleset_string", "foo")
			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
true
--- no_error_log
[error]

=== TEST 8: Ignoring single rule does not trigger merge
--- http_config
init_by_lua '
	local lua_resty_waf = require "resty.waf"

	lua_resty_waf.init()
';
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			ngx.say(waf.need_merge)
			waf:set_option("ignore_rule", 42001)
			ngx.say(waf.need_merge)
		';

	}
--- request
GET /t
--- error_code: 200
--- response_body
false
false
--- no_error_log
[error]

