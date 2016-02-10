use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() ;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: VAR collections variable
--- http_config
	lua_shared_dict storage 10m;
--- config
	location /t {
		access_by_lua '
			local storage = require "lib.storage"
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:set_option("storage_zone", "storage")
			storage.set_var(fw, { rule_setvar_key = "foo", rule_setvar_value = "bar" }, {})
			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(collections.VAR({ _storage_zone = "storage", _pcre_flags = "" }, { value = "foo" }, collections))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: VAR collections variable (type verification)
--- http_config
	lua_shared_dict storage 10m;
--- config
	location /t {
		access_by_lua '
			local FreeWAF = require "fw"
			local fw      = FreeWAF:new()

			fw:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			ngx.say(type(collections.VAR))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
function
--- no_error_log
[error]

