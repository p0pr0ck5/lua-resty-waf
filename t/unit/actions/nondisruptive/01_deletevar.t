use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: deletevar calls storage.delete_var
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

			storage.delete_var = function(waf, ctx, data)
				ngx.log(ngx.DEBUG, "Called storage.delete_var with data.value " .. data.value)
			end

			actions.nondisruptive_lookup["deletevar"]({}, { value = "foo" }, {}, {})
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Called storage.delete_var with data.value foo
--- no_error_log
[error]

