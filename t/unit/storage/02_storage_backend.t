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

=== TEST 1: Default storage backend
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
	';
#
--- config
    location = /t {
        access_by_lua '
			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect("127.0.0.1", 11211)
			memcached:flush_all()

			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

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
Initializing storage type dict
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 2: Define dict storage backend
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
	';
#
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			waf:set_option("storage_backend", "dict")

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
Initializing storage type dict
Initializing an empty collection for FOO
--- no_error_log
[error]

=== TEST 3: Define memcached storage backend
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
	';
#
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			waf:set_option("storage_backend", "memcached")

			local data = {}

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()
			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

			local storage = require "resty.waf.storage"
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
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
	';
#
--- config
    location = /t {
        access_by_lua '

			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			waf:set_option("storage_backend", "redis")

			local data = {}

			local redis_m = require "resty.redis"
			local redis   = redis_m:new()
			redis:connect(waf._storage_redis_host, waf._storage_redis_port)
			redis:flushall()
			waf._storage_redis_delkey_n = 0
			waf._storage_redis_delkey   = {}

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

=== TEST 5: Default invalid storage backend
--- http_config eval
$::HttpConfig . q#
	lua_shared_dict store 10m;
	init_by_lua '
		local lua_resty_waf = require "resty.waf"
	';
#
--- config
    location = /t {
        access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("storage_zone", "store")
			waf:set_option("debug", true)

			waf:set_option("storage_backend", "unicorn_dreams")

			local data = {}

			local storage = require "resty.waf.storage"
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

