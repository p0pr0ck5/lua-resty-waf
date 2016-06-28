use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Connect with defaults
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
Initializing an empty collection
--- no_error_log
[error]
Error in connecting to redis

=== TEST 2: Connect with invalid host
--- http_config
	init_by_lua '
		local lua_resty_waf = require "waf"
		lua_resty_waf.default_option("storage_backend", "redis")
		lua_resty_waf.default_option("debug", true)
	';
	lua_socket_log_errors off;
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()

			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()

			waf:set_option("storage_redis_port", 6397)

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
Error in connecting to redis
--- no_error_log
[error]
Initializing an empty collection
