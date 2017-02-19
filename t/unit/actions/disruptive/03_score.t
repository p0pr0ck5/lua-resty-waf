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

=== TEST 1: SCORE logs and does not exit
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local actions = require "resty.waf.actions"

			actions.disruptive_lookup["SCORE"]({ _debug = true, _debug_log_level = ngx.INFO, _mode = "ACTIVE" }, {})

			ngx.log(ngx.INFO, "We should see this")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Score isn't a thing anymore, see TX.anomaly_score
We should see this
--- no_error_log
[error]

