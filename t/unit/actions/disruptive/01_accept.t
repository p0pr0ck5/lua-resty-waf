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

=== TEST 1: ACCEPT exits the phase with ngx.OK
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local actions = require "resty.waf.actions"

			actions.disruptive_lookup["ACCEPT"]({ _debug = true, _debug_log_level = ngx.INFO, _mode = "ACTIVE" }, {})

			ngx.log(ngx.INFO, "We should not see this")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Rule action was ACCEPT, so ending this phase with ngx.OK
--- no_error_log
[error]
We should not see this

=== TEST 2: ACCEPT does not exit the phase when mode is not ACTIVE
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local actions = require "resty.waf.actions"

			actions.disruptive_lookup["ACCEPT"]({ _debug = true, _debug_log_level = ngx.INFO, _mode = "SIMULATE" }, {})

			ngx.log(ngx.INFO, "We should see this")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Rule action was ACCEPT, so ending this phase with ngx.OK
We should see this
--- no_error_log
[error]
