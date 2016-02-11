use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: TX is accessible in the same phase
--- config
    location = /t {
        access_by_lua '
			local ctx     = ngx.ctx
			local storage = require "lib.storage"

			ctx.rule_setvar_key   = "foo"
			ctx.rule_setvar_value = "bar"
			ctx.tx = {}

			storage.set_var({ _pcre_flags = "" }, ctx, {}, true)

			ngx.ctx = ctx

			ngx.say(storage.get_var({ _pcre_flags = "" }, "foo", {}, ctx.tx))
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: TX is accessible in different phases
--- config
    location = /t {
        access_by_lua '
			local ctx     = ngx.ctx
			local storage = require "lib.storage"

			ctx.rule_setvar_key   = "foo"
			ctx.rule_setvar_value = "bar"
			ctx.tx = {}

			storage.set_var({ _pcre_flags = "" }, ctx, {}, true)

			ngx.ctx = ctx

		';

		content_by_lua '
			local ctx     = ngx.ctx
			local storage = require "lib.storage"

			ngx.say(storage.get_var({ _pcre_flags = "" }, "foo", {}, ctx.tx))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 3: TX does not log shared dict activity
--- config
    location = /t {
        access_by_lua '
			local ctx     = ngx.ctx
			local storage = require "lib.storage"

			ctx.rule_setvar_key   = "foo"
			ctx.rule_setvar_value = "bar"
			ctx.tx = {}

			storage.set_var({ _pcre_flags = "" }, ctx, {}, true)

			ngx.ctx = ctx
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
shared dict
