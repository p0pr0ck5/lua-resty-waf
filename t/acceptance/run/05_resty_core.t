use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: lua_resty_waf runs with resty.core included
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		require "resty.core"
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		}

		header_filter_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		body_filter_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Beginning run of phase access
Beginning run of phase header_filter
Beginning run of phase body_filter
--- no_error_log
[error]

