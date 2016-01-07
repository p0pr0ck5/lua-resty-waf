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
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        access_by_lua '
			local fw = FreeWAF:new()
			fw:set_option("storage_zone", "storage")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log eval
["[error]", qr/Attempted to set FreeWAF storage zone as.*, but that lua_shared_dict does not exist/]

=== TEST 2: Set invalid storage zone
--- http_config
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        access_by_lua '
			local fw = FreeWAF:new()
			fw:set_option("storage_zone", "storage")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 500
--- error_log eval
["[error]", qr/Attempted to set FreeWAF storage zone as.*, but that lua_shared_dict does not exist/]

=== TEST 3: Set variable

--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        access_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "bar" }, {})
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[warn]
Could not add key to persistent storage, increase the size of the lua_shared_dict storage

=== TEST 4: Retrive existing variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "bar" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
Could not add key to persistent storage, increase the size of the lua_shared_dict storage


=== TEST 5: Retrive nonexistent variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
[error]

=== TEST 6: Increment variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = 1 }, {})
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "+1" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
2
--- no_error_log
Could not add key to persistent storage, increase the size of the lua_shared_dict storage

=== TEST 7: Decrement variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = 1 }, {})
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "-1" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
0
--- no_error_log
Could not add key to persistent storage, increase the size of the lua_shared_dict storage

=== TEST 8: Multiply variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = 2 }, {})
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "*5" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
10
--- no_error_log
Could not add key to persistent storage, increase the size of the lua_shared_dict storage

=== TEST 9: Divide variable
--- http_config
	lua_shared_dict storage 10m;
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = 9 }, {})
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "/3" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
3
--- no_error_log
Could not add key to persistent storage, increase the size of the lua_shared_dict storage

=== TEST 10: Silent return if no shm is configured
--- http_config
	init_by_lua '
		FreeWAF = require "FreeWAF.fw"
	';
--- config
    location = /t {
        content_by_lua '
			local fw      = FreeWAF:new()
			local storage = require "FreeWAF.lib.storage"
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "bar" }, {})
			local value = storage.get_var(fw, "foo", {})
			ngx.say(value)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
--- no_error_log
attempt to index local 'shm'
