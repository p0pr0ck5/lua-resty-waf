use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 17 * blocks();

check_accum_error_log();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty, persist and re-initialize a collection
--- http_config
    init_by_lua '
        local lua_resty_waf = require "waf"
        lua_resty_waf.default_option("storage_backend", "redis")
        lua_resty_waf.default_option("debug", true)
    ';
--- config
    location = /t {
        access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

            local storage = require "lib.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)

            storage.persist(waf, ctx.storage)
        ';

        content_by_lua 'ngx.say("OK")';
    }

    location = /s {
		access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		';
	}
--- request eval
["GET /t", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["OK\n", "COUNT: 1\n"]
--- error_log
Initializing storage type redis
Initializing an empty collection for FOO
Persisting storage type redis
Examining FOO
Persisting value: {"COUNT":1}
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 2: Initialize empty, set with future expiry, persist, delay, and re-initialize a collection
--- http_config
    init_by_lua '
        local lua_resty_waf = require "waf"
        lua_resty_waf.default_option("storage_backend", "redis")
        lua_resty_waf.default_option("debug", true)
    ';
--- config
    location = /t {
        access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

            local storage = require "lib.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 10)

            storage.persist(waf, ctx.storage)

			ngx.sleep(3)
        ';

        content_by_lua 'ngx.say("OK")';
    }

    location = /s {
		access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		';
	}
--- request eval
["GET /t", "GET /s"]
--- timeout
4
--- error_code eval
[200, 200]
--- response_body eval
["OK\n", "COUNT: 1\n"]
--- error_log
Initializing storage type redis
Initializing an empty collection for FOO
Persisting storage type redis
Examining FOO
Persisting value: {"
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 3: Initialize empty, set with expiry, persist, delay, re-initialize, and re-persist
--- http_config
    init_by_lua '
        local lua_resty_waf = require "waf"
        lua_resty_waf.default_option("storage_backend", "redis")
        lua_resty_waf.default_option("debug", true)
    ';
--- config
    location = /t {
        access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

            local storage = require "lib.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 1)

            storage.persist(waf, ctx.storage)

			ngx.sleep(3)
        ';

        content_by_lua 'ngx.say("OK")';
    }

    location = /s {
		access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		';
	}
--- request eval
["GET /t", "GET /s"]
--- timeout
4
--- error_code eval
[200, 200]
--- response_body eval
["OK\n", ""]
--- error_log
Initializing storage type redis
Initializing an empty collection for FOO
Persisting storage type redis
Examining FOO
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 4: Initialize empty, set some with expiry, persist, delay, re-initialize, and re-persist
--- http_config
    init_by_lua '
        local lua_resty_waf = require "waf"
        lua_resty_waf.default_option("storage_backend", "redis")
        lua_resty_waf.default_option("debug", true)
    ';
--- config
    location = /t {
        access_by_lua '
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

            local storage = require "lib.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 1)

            local element = { col = "FOO", key = "COUNT_OTHER", value = 2 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 10)

            storage.persist(waf, ctx.storage)
        ';

        content_by_lua 'ngx.say("OK")';
    }

    location = /s {
		access_by_lua '
			ngx.sleep(3)
            local lua_resty_waf = require "waf"
            local waf           = lua_resty_waf:new()

			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}
			waf._storage_redis_setkey_f = true
			waf._storage_redis_setkey   = {}

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]

			storage.persist(waf, data)
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		';
	}
--- request eval
["GET /t", "GET /s"]
--- timeout
4
--- error_code eval
[200, 200]
--- response_body eval
["OK\n", "COUNT_OTHER: 2\n"]
--- error_log
Initializing storage type redis
Initializing an empty collection for FOO
Persisting storage type redis
Examining FOO
--- no_error_log
[error]
Not persisting a collection that wasn't altered

