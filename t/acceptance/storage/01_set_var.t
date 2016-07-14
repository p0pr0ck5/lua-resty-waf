use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Set a var - confirm the set value
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- error_log
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 2: Set a var - confirm the __altered flag is set
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["__altered"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
true
--- error_log
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 3: Override an existing value
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- error_log
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 4: Increment an existing value
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
6
--- error_log
Setting FOO:COUNT to 6
--- no_error_log
[error]

=== TEST 5: Increment an non-existing value
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ blah = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- error_log
Incrementing a non-existing value
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 6: Fail to increment a non-numeric value 1/2
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = "blah" })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log
Cannot increment a value that was not previously a number
--- no_error_log
Setting FOO:COUNT to 6

=== TEST 7: Fail to increment a non-numeric value 2/2
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = 3 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = nil, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		';

		content_by_lua '
			ngx.say(ngx.ctx["COUNT"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
3
--- error_log
Failed to increment a non-number, falling back to existing value
Setting FOO:COUNT to 3
--- no_error_log
[error]

