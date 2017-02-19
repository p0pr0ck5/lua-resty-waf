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

=== TEST 1: GET request with a body
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
foo=bar
--- more_headers
Accept: */*
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
http header: "Content-Length: 7"
"id":20002

=== TEST 2: POST request with a body
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
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
http header: "Content-Length: 7"
--- no_error_log
"id":20002

=== TEST 3: POST request does not have a Content-Length header
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
"POST /t HTTP/1.0\r
Host: localhost\r
Accept: */*\r
\nfoo=bar"
--- error_code: 200
--- no_error_log
http header: "Content-Length: 7"
--- error_log
"id":20004

=== TEST 4: POST request with a body
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
Content-Type: application/x-www-form-urlencoded
--- error_code: 200
--- error_log
http header: "Content-Length: 7"
--- no_error_log
"id":20004

=== TEST 5: Content-Encoding header contains 'identity'
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
Accept: */*
Content-Encoding: Identity
--- error_code: 200
--- error_log
"id":20005
--- no_error_log
[error]

=== TEST 6: HTTP/1.1 request sent with a Pragma:no-cache header, but no corresponding Cache-Control header
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
Pragma: no-cache
Accept: */*
--- error_code: 200
--- error_log
"id":20011
--- no_error_log
[error]

=== TEST 7: Abnormal Range header
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
Accept: */*
Range: bytes=0-9999
--- error_code: 200
--- error_log
"id":20012
--- no_error_log
[error]

=== TEST 8: Abnormal Range header
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
Accept: */*
Range: bytes=0-1,2-3,4-5,6-7,8-9,10-
User-Agent: test
--- error_code: 200
--- error_log
"id":20013
--- no_error_log
[error]

=== TEST 9: Abnormal Request-Range header
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
Accept: */*
Request-Range: bytes=0-1,2-3,4-5,6-7,8-9,10-
--- error_code: 200
--- error_log
"id":20014
--- no_error_log
[error]

=== TEST 10: Duplicate/broken connection header
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
Accept: */*
Connection: keep-alive, close
--- error_code: 200
--- error_log
"id":20015
--- no_error_log
[error]

