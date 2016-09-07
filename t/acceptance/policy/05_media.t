use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Whitelist .mpg
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mpg
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 2: Whitelist .mpeg
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mpeg
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 3: Whitelist .mp3
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mp3
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 4: Whitelist .mp4
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.mp4
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 5: Whitelist .avi
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.avi
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 6: Whitelist .flv
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.flv
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 7: Whitelist .swf
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.swf
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 8: Whitelist .wma
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.wma
--- error_code: 404
--- error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 9: Do not whitelist unmatched extension (.wmd)
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.wmd
--- error_code: 404
--- no_error_log
Match of rule 11007
Rule action was ACCEPT

=== TEST 10: Do not whitelist non-final extension
--- http_config
init_by_lua_block{
	if (os.getenv("LRW_COVERAGE")) then
		runner = require "luacov.runner"
		runner.tick = true
		runner.init({savestepsize = 110})
		jit.off()
	end
}
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("ignore_rule", 11001)
		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';
--- request
GET /foo.avi.exe
--- error_code: 404
--- no_error_log
Match of rule 11007
Rule action was ACCEPT

