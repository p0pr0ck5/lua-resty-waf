use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: status sets ctx.rule_status
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 1})
		jit.off()
	end
}
--- config
	location /t {
		content_by_lua '
			local actions = require "resty.waf.actions"

			local ctx = {}

			local new_status = ngx.HTTP_NOT_FOUND

			actions.nondisruptive_lookup["status"](
				{ _debug = true, _debug_log_level = ngx.INFO, _deny_status = ngx.HTTP_FORBIDDEN },
				new_status,
				ctx
			)

			ngx.say(ctx.rule_status)
		';
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

