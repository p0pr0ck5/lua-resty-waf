use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 17 * blocks();

check_accum_error_log();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Initialize empty, persist and re-initialize a collection
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

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

            local storage = require "resty.waf.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)

            storage.persist(waf, ctx.storage)
        }

        content_by_lua_block {ngx.say("OK")}
    }

    location = /s {
		access_by_lua_block {
            local lua_resty_waf = require "resty.waf"
            local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

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
		}
	}
--- request eval
["GET /t", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["OK\n", "COUNT: 1\n"]
--- error_log
Initializing storage type memcached
Initializing an empty collection for FOO
Persisting storage type memcached
Examining FOO
Persisting value: {"COUNT":1}
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 2: Initialize empty, set with future expiry, persist, delay, and re-initialize a collection
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

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

            local storage = require "resty.waf.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 1)

            storage.persist(waf, ctx.storage)

			ngx.sleep(.5)
        }

        content_by_lua_block {ngx.say("OK")}
    }

    location = /s {
		access_by_lua_block {
            local lua_resty_waf = require "resty.waf"
            local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		}
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
Initializing storage type memcached
Initializing an empty collection for FOO
Persisting storage type memcached
Examining FOO
Persisting value: {"
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 3: Initialize empty, set with expiry, persist, delay, re-initialize, and re-persist
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

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

            local storage = require "resty.waf.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, .2)

            storage.persist(waf, ctx.storage)

			ngx.sleep(.5)
        }

        content_by_lua_block {ngx.say("OK")}
    }

    location = /s {
		access_by_lua_block {
            local lua_resty_waf = require "resty.waf"
            local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		}
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
Initializing storage type memcached
Initializing an empty collection for FOO
Persisting storage type memcached
Examining FOO
--- no_error_log
[error]
Not persisting a collection that wasn't altered

=== TEST 4: Initialize empty, set some with expiry, persist, delay, re-initialize, and re-persist
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

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

            local ctx = { storage = {}, col_lookup = { FOO = "FOO" } }

            local storage = require "resty.waf.storage"
            storage.initialize(waf, ctx.storage, "FOO")

            local element = { col = "FOO", key = "COUNT", value = 1 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, .2)

            local element = { col = "FOO", key = "COUNT_OTHER", value = 2 }
            storage.set_var(waf, ctx, element, element.value)
            storage.expire_var(waf, ctx, element, 1)

            storage.persist(waf, ctx.storage)
        }

        content_by_lua_block {ngx.say("OK")}
    }

    location = /s {
		access_by_lua_block {
			ngx.sleep(.5)
            local lua_resty_waf = require "resty.waf"
            local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "memcached")
			waf:set_option("debug", true)

			local data = {}

			local storage = require "resty.waf.storage"
			storage.initialize(waf, data, "FOO")

			ngx.ctx = data["FOO"]

			storage.persist(waf, data)
		}

		content_by_lua_block {
			for k in pairs(ngx.ctx) do
				if (k ~= "__altered" and not k:find("__", 1, true)) then
					ngx.say(tostring(k) .. ": " .. tostring(ngx.ctx[k]))
				end
			end
		}
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
Initializing storage type memcached
Initializing an empty collection for FOO
Persisting storage type memcached
Examining FOO
--- no_error_log
[error]
Not persisting a collection that wasn't altered

