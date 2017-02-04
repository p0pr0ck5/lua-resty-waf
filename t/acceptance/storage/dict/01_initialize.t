use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 5 * blocks() - 6;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty collection
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
Initializing storage type dict
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 2: Initialize pre-populated collection
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

			local var = require("cjson").encode({ a = "b" })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
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

			local var = require("cjson").encode({ a = "b", c = "d", __expire_c = ngx.time() - 10 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
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

			local var = require("cjson").encode({ a = "b", __expire_a = ngx.time() + 10, c = "d", __expire_c = ngx.time() - 10 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set("FOO", var)

			local data = {}

			local storage = require "resty.waf.storage"
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

=== TEST 5: Fail when attempting to initialize storage when storage_zone is undefined
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

			waf:set_option("debug", true)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 500
--- error_log
[error]
Initializing storage type dict
No storage_zone configured for memory-based persistent storage

