use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 5 * blocks() + 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Persist a collection
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("storage_backend", "dict")
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

			storage.persist(waf, ctx.storage)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Persisting storage type dict
Examining FOO
Persisting value: {"COUNT":1}
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 2: Don't persist an unaltered collection
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("storage_backend", "dict")
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

			storage.persist(waf, ctx.storage)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Examining FOO
Not persisting a collection that wasn't altered
--- no_error_log
[error]
Persisting value: {"

=== TEST 3: Persist an unaltered collection with expired keys
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("storage_backend", "dict")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }
			local var = require("cjson").encode({ COUNT = 5, __expire_COUNT = ngx.time() - 10, BAR = 1 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local storage = require "resty.waf.storage"
			storage.initialize(waf, ctx.storage, "FOO")

			storage.persist(waf, ctx.storage)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Examining FOO
Persisting value: {"BAR":1}
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 4: Don't persist the TX collection
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

			local ctx = { storage = { TX = {} }, col_lookup = { TX = "TX" } }
			local var = require("cjson").encode({ COUNT = 5 })

			local storage = require "resty.waf.storage"

			local element = { col = "TX", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)

			storage.persist(waf, ctx.storage)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]
Examining TX
Not persisting a collection that wasn't altered
Persisting value: {"

