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

=== TEST 1: Set a var - confirm the set value
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
1
--- error_log
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 2: Set a var - confirm the __altered flag is set
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
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 3: Override an existing value
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

			local element = { col = "FOO", key = "COUNT", value = 1 }
			storage.set_var(waf, ctx, element, element.value)

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
1
--- error_log
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 4: Increment an existing value
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

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

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
6
--- error_log
Setting FOO:COUNT to 6
--- no_error_log
[error]

=== TEST 5: Increment an non-existing value
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
			local var = require("cjson").encode({ blah = 5 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set(storage.col_prefix .. "FOO", var)

			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

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
1
--- error_log
Incrementing a non-existing value
Setting FOO:COUNT to 1
--- no_error_log
[error]

=== TEST 6: Fail to increment a non-numeric value 1/2
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
			local var = require("cjson").encode({ COUNT = "blah" })
			local shm = ngx.shared[waf._storage_zone]
			shm:set(storage.col_prefix .. "FOO", var)

			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = 1, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

			ngx.ctx = ctx.storage["FOO"]
		}

		content_by_lua_block {
			ngx.say(ngx.ctx["COUNT"])
		}
	}
--- request
GET /t
--- error_code: 500
--- error_log
Cannot increment a value that was not previously a number
--- no_error_log
Setting FOO:COUNT to 6

=== TEST 7: Fail to increment a non-numeric value 2/2
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
			local var = require("cjson").encode({ COUNT = 3 })
			local shm = ngx.shared[waf._storage_zone]
			shm:set(storage.col_prefix .. "FOO", var)

			storage.initialize(waf, ctx.storage, "FOO")

			local element = { col = "FOO", key = "COUNT", value = nil, inc = 1 }
			storage.set_var(waf, ctx, element, element.value)

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
3
--- error_log
Failed to increment a non-number, falling back to existing value
Setting FOO:COUNT to 3
--- no_error_log
[error]

=== TEST 8: Bail out when collection is unitialized
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
			storage.set_var(waf, ctx, element, element.value)
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
