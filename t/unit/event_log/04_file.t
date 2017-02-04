use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 2 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Write an entry to file without error
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local log           = require "resty.waf.log"
			local waf           = lua_resty_waf:new()

			waf:set_option("event_log_target", "file")
			waf:set_option("event_log_target_path", "/tmp/waf.log")

			log.write_log_events[waf._event_log_target](waf, {foo = "bar"})
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
--- no_error_log
[error]

=== TEST 2: Fatally fail when path is unset
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local log           = require "resty.waf.log"
			local waf           = lua_resty_waf:new()

			waf:set_option("event_log_target", "file")

			log.write_log_events[waf._event_log_target](waf, {foo = "bar"})
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 500
--- error_log
Event log target path is undefined in file logger

=== TEST 3: Warn when file path cannot be opened
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local log           = require "resty.waf.log"
			local waf           = lua_resty_waf:new()

			waf:set_option("event_log_target", "file")
			waf:set_option("event_log_target_path", "/tmp/waf.log")

			io.open = function() return false end

			log.write_log_events[waf._event_log_target](waf, {foo = "bar"})
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Could not open /tmp/waf.log
--- no_error_log
[error]
