use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: No User-Agent sent
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
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
--- no_error_log
"id":35001
"id":35003

=== TEST 2: Valid User-Agent sent
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
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
User-Agent: Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36
Accept: */*
--- error_code: 200
--- no_error_log
"id":35001
"id":35003

=== TEST 3: Known automated scanner
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
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
User-Agent: WebInspect
Accept: */*
--- error_code: 200
--- error_log
"id":35001
--- no_error_log
"id":35003

=== TEST 4: Known malicious User-Agent
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
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
User-Agent: Internet-Exprorer
Accept: */*
--- error_code: 200
--- error_log
"id":35003
--- no_error_log
"id":35001

