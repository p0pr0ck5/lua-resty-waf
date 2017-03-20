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

			local waf = { _debug = true, _debug_log_level = ngx.INFO, _mode = 'ACTIVE' }
			ngx.say(waf._mode)

			local new_mode = 'SIMULATE'

			actions.nondisruptive_lookup["mode_update"](
				waf,
				new_mode
			)

			ngx.say(waf._mode)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
ACTIVE
SIMULATE
--- error_log
Overriding mode from ACTIVE to SIMULATE
--- no_error_log
[error]

