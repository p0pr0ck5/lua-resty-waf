use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Set valid storage zone
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		lua_resty_waf = require "resty.waf"
	';
--- config
    location = /t {
        access_by_lua '
			local waf      = lua_resty_waf:new()
			waf:set_option("storage_zone", "storage")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log eval
["[error]", qr/Attempted to set lua_resty_waf storage zone as.*, but that lua_shared_dict does not exist/]

=== TEST 2: Set invalid storage zone
--- http_config
	init_by_lua '
		lua_resty_waf = require "resty.waf"
	';
--- config
    location = /t {
        access_by_lua '
			local waf      = lua_resty_waf:new()
			waf:set_option("storage_zone", "storage")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 500
--- error_log eval
["[error]", qr/Attempted to set lua-resty-waf storage zone as.*, but that lua_shared_dict does not exist/]

