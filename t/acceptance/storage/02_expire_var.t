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

=== TEST 1: Expire a var - confirm the set value and __altered flag
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)
			storage.expire_var(waf,ctx, element, 10)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["__altered"])
			ngx.say(ngx.ctx["__expire_COUNT"] == ngx.now() + 10)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
true
--- error_log
Setting FOO:COUNT to 1
Expiring FOO:COUNT in 10
--- no_error_log
[error]

=== TEST 2: Bail out when collection is unitialized
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
#
--- config
    location = /t {
        access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local storage       = require "resty.waf.storage"

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			local ctx = { storage = {}, col_lookup = {} }

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.expire_var(waf, ctx, element, 10)
		}

		content_by_lua_block {ngx.exit(ngx.OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
FOO not initialized
--- no_error_log
[error]
