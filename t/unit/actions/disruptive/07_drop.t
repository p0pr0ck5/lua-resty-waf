use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: DROP exits the phase with ngx.HTTP_CLOSE
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local actions = require "resty.waf.actions"

			actions.disruptive_lookup["DROP"]({ _debug = true, _debug_log_level = ngx.INFO, _mode = "ACTIVE" }, {})

			ngx.log(ngx.INFO, "We should not see this")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code:
--- error_log
Rule action was DROP, ending eith ngx.HTTP_CLOSE
--- no_error_log
[error]
We should not see this

=== TEST 2: DROP does not exit the phase when mode is not ACTIVE
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local actions = require "resty.waf.actions"

			actions.disruptive_lookup["DROP"]({ _debug = true, _debug_log_level = ngx.INFO, _mode = "SIMULATE" }, {})

			ngx.log(ngx.INFO, "We should see this")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Rule action was DROP, ending eith ngx.HTTP_CLOSE
We should see this
--- no_error_log
[error]
