use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Request with no Host header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- raw_request eval
"GET /t HTTP/1.0\r
Accept: */*
User-Agent: Hostless
\r\n\n"
--- error_code: 200
--- error_log
"id":21001
--- no_error_log
[error]

=== TEST 2: Request with no Accept header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- more_headers
User-Agent: Acceptless
--- error_code: 200
--- error_log
"id":21003
--- no_error_log
[error]

=== TEST 3: Request with empty Accept header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- more_headers
Accept:
--- error_code: 200
--- error_log
"id":21005
--- no_error_log
[error]

=== TEST 4: Request with no User-Agent header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- error_code: 200
--- error_log
"id":21006
--- no_error_log
[error]

=== TEST 5: Request with empty User-Agent header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
GET /t
--- more_headers
User-Agent:
--- error_code: 200
--- error_log
"id":21007
--- no_error_log
[error]

=== TEST 6: Request contains Content-Length but no Content-Type
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- request
POST /t
foo=bar
--- more_headers
Accept: */*
User-Agent: Typeless
--- error_code: 200
--- error_log
"id":21009
--- no_error_log
[error]

=== TEST 7: Request with IP address in Host header
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("ignore_rule", 11001)
			waf:set_option("event_log_altered_only", false)
			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}

		log_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:write_log_events()
		}
	}
--- raw_request eval
"GET /t HTTP/1.0\r
Host: 127.0.0.1
Accept: */*
\r\n\n"
--- error_code: 200
--- error_log
"id":21010
--- no_error_log
[error]

