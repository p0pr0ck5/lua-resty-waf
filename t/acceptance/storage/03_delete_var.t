use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Delete a var - confirm the value is gone
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
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT" }
			storage.delete_var(waf, ctx, element)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["COUNT"])
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- error_log
Deleting FOO:COUNT
--- no_error_log
[error]

=== TEST 2: Delete a var - confirm the __altered flag is set
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

			local storage = require "resty.waf.storage"
			storage.col_prefix = ngx.worker.pid()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set(storage.col_prefix .. "FOO", var)

			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT" }
			storage.delete_var(waf, ctx, element)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["__altered"])
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- error_log
Deleting FOO:COUNT
--- no_error_log
[error]

=== TEST 3: Delete a non-existing var
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
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "BAR" }
			storage.delete_var(waf, ctx, element)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["BAR"])
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- error_log
BAR was not found in FOO
--- no_error_log
[error]

=== TEST 4: Delete a non-existing var - confirm the altered flag is unset
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
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "BAR" }
			storage.delete_var(waf, ctx, element)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["__altered"])
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
false
--- error_log
BAR was not found in FOO
--- no_error_log
[error]

=== TEST 5: Bail out when collection is unitialized
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
			storage.delete_var(waf, ctx, element)
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
