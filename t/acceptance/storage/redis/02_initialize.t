use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() + 6;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty collection
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()

			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Initializing storage type redis
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 2: Initialize pre-populated collection
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local var = { a = "b" }

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
a: b
false
--- no_error_log
[error]
Initializing an empty collection for FOO
Removing expired key:

=== TEST 3: Initialize pre-populated collection with expired keys
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local var = { a = "b", c = "d", __expire_c = ngx.time() - 10 }
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
a: b
true
--- error_log
Removing expired key: c
--- no_error_log
[error]
Initializing an empty collection for FOO

=== TEST 4: Initialize pre-populated collection with only some expired keys
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local var = { a = "b", __expire_a = ngx.time() + 10, c = "d", __expire_c = ngx.time() - 10 }
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
a: b
true
--- error_log
Removing expired key: c
--- no_error_log
[error]
Initializing an empty collection for FOO

=== TEST 5: Test types of initialized values
--- http_config
	init_by_lua '
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 110})
			jit.off()
		end

		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local var = { a = "b", c = 5 }

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		';

		content_by_lua '
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]) .. " (" .. type(ngx.ctx[k]) .. ")")
				end
			end
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
a: b (string)
c: 5 (number)
--- no_error_log
[error]

