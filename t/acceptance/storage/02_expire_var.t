use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() + 3;

add_response_body_check(sub {
	my ($block, $body, $req_idx, $repeated_req_idx, $dry_run) = @_;

	my $name = $block->name;

	SKIP: {
		skip "$name - resp_title - tests skipped due to $dry_run", 1 if $dry_run;

		is($body, sprintf("%s\n%d\n", 'true', time + 10), "$name - expire time is set (req $repeated_req_idx)" );
	}
});

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Expire a var - confirm the set value and __altered flag
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			local storage = require "lib.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)
			storage.expire_var(waf,ctx, element, 10)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["__altered"])
			ngx.say(ngx.ctx["__expire_COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Setting FOO:COUNT to 1
Expiring FOO:COUNT in 10
--- no_error_log
[error]

