use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: No override, default DENY behavior
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 403
--- error_log
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]

=== TEST 2: Override DENY action
--- config
	location /t {
		access_by_lua '
			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 404
--- error_log
Override DENY action
--- no_error_log
[error]
Rule action was DENY, so telling nginx to quit

=== TEST 3: Override DENY action for valid request
--- config
	location /t {
		access_by_lua '
			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=notathreat
--- more_headers
Accept: */*
--- error_code: 200
--- no_error_log
[error]
Rule action was DENY, so telling nginx to quit
Override DENY action

=== TEST 4: Override invalid action
--- config
	location /t {
		access_by_lua '
			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "FOO", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 500
--- error_log
FOO is not a valid action to override
--- no_error_log
Rule action was DENY, so telling nginx to quit
Override DENY action

=== TEST 5: No override, default ACCEPT behavior
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t
--- more_headers
Accept: */*
--- error_code: 200
--- error_log
Rule action was ACCEPT, so ending this phase with ngx.OK
--- no_error_log
[error]

=== TEST 6: Override ACCEPT and DENY action for valid request
--- config
	location /t {
		access_by_lua '
			local accept_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "Override ACCEPT action")
			end

			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:set_option("hook_action", "ACCEPT", accept_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t
--- more_headers
Accept: */*
--- error_code: 200
--- error_log
Override ACCEPT action
--- no_error_log
[error]
Rule action was DENY, so telling nginx to quit
Override DENY action

=== TEST 7: Check waf object in hook
--- config
	location /t {
		access_by_lua '
			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "waf mode is " .. waf._mode)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 404
--- error_log
waf mode is ACTIVE
Override DENY action
--- no_error_log
[error]
Rule action was DENY, so telling nginx to quit

=== TEST 8: Action hooks run in SIMULATE mode
--- config
	location /t {
		access_by_lua '
			local deny_override = function(waf, ctx)
				ngx.log(ngx.DEBUG, "waf mode is " .. waf._mode)
				ngx.log(ngx.DEBUG, "Override DENY action")
				ngx.status = ngx.HTTP_NOT_FOUND
			end

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "SIMULATE") -- explicitly set
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 404
--- error_log
waf mode is SIMULATE
Override DENY action
--- no_error_log
[error]
Rule action was DENY, so telling nginx to quit

=== TEST 9: Non-function passed as hook
--- config
	location /t {
		access_by_lua '
			local deny_override = 42

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("hook_action", "DENY", deny_override)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?a=alert(1)
--- more_headers
Accept: */*
--- error_code: 500
--- error_log
hook_action must be defined as a function
--- no_error_log
Rule action was DENY, so telling nginx to quit

