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

=== TEST 1: status sets ctx.rule_status
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local actions = require "resty.waf.actions"

			local ctx = {}

			local new_status = ngx.HTTP_NOT_FOUND

			actions.nondisruptive_lookup["status"](
				{ _debug = true, _debug_log_level = ngx.INFO, _deny_status = ngx.HTTP_FORBIDDEN },
				new_status,
				ctx
			)

			ngx.say(ctx.rule_status)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
404
--- error_log
Overriding status from 403 to 404
--- no_error_log
[error]

