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

=== TEST 1: Phases are defined as a table
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(type(phase.phases))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
--- no_error_log
[error]

=== TEST 2: Four phases are currently defined
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local phase = require "resty.waf.phase"
			local util  = require "resty.waf.util"
			ngx.say(table.getn(util.table_keys(phase.phases)))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
4
--- no_error_log
[error]

=== TEST 3: Init is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("init"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 4: Init worker is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("init_worker"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 5: Set is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("set"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 6: Rewrite is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("rewrite"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 7: Access is a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("access"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 8: Content is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("content"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

=== TEST 9: Header filter is a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("header_filter"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 10: Body filter is a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("body_filter"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 11: Log is a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("log"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- no_error_log
[error]

=== TEST 12: Timer is not a valid phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local phase = require "resty.waf.phase"
			ngx.say(phase.is_valid_phase("timer"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- no_error_log
[error]

