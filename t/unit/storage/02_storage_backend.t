use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Default storage backend
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
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
Initializing storage type dict
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 2: Define dict storage backend
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "dict")

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
Initializing storage type dict
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 3: Define memcached storage backend
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "memcached")

			local data = {}

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

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

=== TEST 4: Define redis storage backend
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '

			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "redis")

			local data = {}

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

			local storage = require "lib.storage"
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

=== TEST 5: Default invalid storage backend
--- http_config
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_zone", "store")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_backend", "unicorn_dreams")

			local data = {}

			local storage = require "lib.storage"
			storage.initialize(waf, data, "FOO")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 500
--- error_log
[error]
unicorn_dreams is not a valid persistent storage backend
--- no_error_log
Initializing an empty collection for FOO

