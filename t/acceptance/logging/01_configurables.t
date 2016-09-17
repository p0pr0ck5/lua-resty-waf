use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() + 12;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Log ngx.var to event log
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("event_log_ngx_vars", "args")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- error_log
"ngx":{
"args":"foo=alert(1)"

=== TEST 2: Do not log ngx.var if option is unset
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- no_error_log
"ngx":{
"args":"foo=alert(1)"

=== TEST 3: Log request arguments
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("event_log_request_arguments", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- error_log
"uri_args":{"foo":"alert(1)"}
--- no_error_log
[error]

=== TEST 4: Do not log request arguments if option is unset
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- error_code: 403
--- no_error_log
"uri_args":{"foo":"alert(1)"}
[error]

=== TEST 5: Log request headers
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("event_log_request_headers", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- more_headers
X-Foo: Bar
--- error_code: 403
--- error_log
"request_headers":{
"host":"localhost",
"x-foo":"Bar",
---  no_error_log
[error]

=== TEST 6: Do not log request headers if option is unset
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
GET /t?foo=alert(1)
--- more_headers
X-Foo: Bar
--- error_code: 403
--- error_log
---  no_error_log
[error]
"request_headers":{
"host":"localhost",
"x-foo":"Bar",

=== TEST 7: Log request body
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("event_log_request_body", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
POST /t
foo=alert(1)
--- more_headers
Content-Type: application/x-www-form-urlencoded
--- error_code: 403
--- error_log
"request_body":{"foo":"alert(1)"}
--- no_error_log
[error]

=== TEST 8: Do not log request body if option is unset
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';

		log_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		';
	}
--- request
POST /t
foo=alert(1)
--- error_code: 403
--- no_error_log
"request_body":{"foo":"alert(1)"}
[error]

