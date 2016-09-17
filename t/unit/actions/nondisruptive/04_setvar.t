use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: setvar calls storage.set_var
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 50})
		jit.off()
	end
}
--- config
	location /t {
		access_by_lua '
			local actions = require "resty.waf.actions"
			local storage = require "resty.waf.storage"
			local util    = require "resty.waf.util"

			util.parse_dynamic_value = function(waf, key, collections)
				return collections[key]
			end

			storage.set_var = function(waf, ctx, data, value)
				ngx.log(ngx.DEBUG, "Called storage.set_var with data.value " .. data.value .. " and value " .. value)
			end

			actions.nondisruptive_lookup["setvar"]({}, { value = "foo", time = "foo" }, {}, { foo = "dynamic-foo" })
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Called storage.set_var with data.value foo and value dynamic-foo
--- no_error_log
[error]

