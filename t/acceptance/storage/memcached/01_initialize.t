use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 5 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty collection
--- http_config
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect("127.0.0.1", 11211)
			memcached:flush_all()

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Initializing storage type memcached
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 2: Initialize pre-populated collection
--- http_config
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local memcached_m   = require "resty.memcached"
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local var = require("cjson").encode({ a = "b" })

			local memcached = memcached_m:new()
			memcached:connect("127.0.0.1", 11211)
			memcached:set("FOO", var)

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
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local memcached_m   = require "resty.memcached"
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local var = require("cjson").encode({ a = "b", c = "d", __expire_c = ngx.time() - 10 })

			local memcached = memcached_m:new()
			memcached:connect("127.0.0.1", 11211)
			memcached:set("FOO", var)

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
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local memcached_m   = require "resty.memcached"
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local var = require("cjson").encode({ a = "b", __expire_a = ngx.time() + 10, c = "d", __expire_c = ngx.time() - 10 })

			local memcached = memcached_m:new()
			memcached:connect("127.0.0.1", 11211)
			memcached:set("FOO", var)

			local data = {}

			local storage = require "lib.storage"
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

