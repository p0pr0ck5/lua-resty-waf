use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Connect with defaults
--- http_config
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

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
Initializing an empty collection
--- no_error_log
[error]
Error in connecting to memcached

=== TEST 2: Connect with invalid host
--- http_config
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
		lua_resty_waf.default_option("storage_backend", "memcached")
		lua_resty_waf.default_option("debug", true)
	';
	lua_socket_log_errors off;
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

			waf:set_option("storage_memcached_port", 11221)

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
Error in connecting to memcached
--- no_error_log
[error]
Initializing an empty collection
