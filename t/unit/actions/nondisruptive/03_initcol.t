use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 4 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: initcol calls storage.initialize
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

			storage.initialize = function(waf, storage, parsed)
				ngx.log(ngx.DEBUG, "Called storage.initialize with parsed " .. parsed)
			end

			actions.nondisruptive_lookup["initcol"](
				{ _debug = true, _debug_log_level = ngx.DEBUG },
				{ col = "IP", value = "IP" },
				{ col_lookup = {}, storage = {} },
				{ IP = "127.0.0.1" }
			)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Initializing IP as 127.0.0.1
Called storage.initialize with parsed 127.0.0.1
--- no_error_log
[error]

