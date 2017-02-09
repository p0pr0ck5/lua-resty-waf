use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() + 6;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty collection
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")
			waf:set_option("debug", true)

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()

			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
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
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")
			waf:set_option("debug", true)

			local var = { a = "b" }

			local storage = require "resty.waf.storage"
			storage.col_prefix = ngx.worker.pid()

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset(storage.col_prefix .. "FOO", var)

			local data = {}

			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		}
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
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")
			waf:set_option("debug", true)

			local var = { a = "b", c = "d", __expire_c = ngx.time() - 10 }
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

			local storage = require "resty.waf.storage"
			storage.col_prefix = ngx.worker.pid()

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset(storage.col_prefix .. "FOO", var)

			local data = {}

			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		}
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
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")
			waf:set_option("debug", true)

			local var = { a = "b", __expire_a = ngx.time() + 10, c = "d", __expire_c = ngx.time() - 10 }
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

			local storage = require "resty.waf.storage"
			storage.col_prefix = ngx.worker.pid()

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset(storage.col_prefix .. "FOO", var)

			local data = {}

			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end

			ngx.say(ngx.ctx["__altered"])
		}
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
--- http_config eval
$::HttpConfig . q#
	init_by_lua_block {
		local lua_resty_waf = require "resty.waf"
	}
#
--- config
    location = /t {
        access_by_lua_block {
			local redis_m   = require "resty.redis"
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")
			waf:set_option("debug", true)

			local var = { a = "b", c = 5 }

			local storage = require "resty.waf.storage"
			storage.col_prefix = ngx.worker.pid()

			local redis = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			redis:hmset(storage.col_prefix .. "FOO", var)

			local data = {}

			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered") then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]) .. " (" .. type(ngx.ctx[k]) .. ")")
				end
			end
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
a: b (string)
c: 5 (number)
--- no_error_log
[error]

