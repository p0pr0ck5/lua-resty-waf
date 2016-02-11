use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: TX collections variable
--- config
	location /t {
		access_by_lua '
			local ctx     = ngx.ctx
			local storage = require "lib.storage"
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			ctx.rule_setvar_key   = "foo"
			ctx.rule_setvar_value = "bar"
			ctx.tx = {}

			storage.set_var(fw, ctx, {}, true)
			fw:exec()
		';

		content_by_lua '
			local ctx         = ngx.ctx
			local collections = ctx.collections

			ngx.say(collections.TX({ _pcre_flags = "" }, { value = "foo" }, collections, ctx.tx))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: TX collections variable (type verification)
--- http_config
	lua_shared_dict storage 10m;
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.TX))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
function
--- no_error_log
[error]

