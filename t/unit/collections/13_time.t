use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: TIME collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			-- mock out ngx.localtime as a global function for testing
			localtime = function() return "1991-09-13 16:21:59" end
			ngx.localtime = localtime

			--ngx.time as well
			time = function() return "684793319" end
			ngx.time = time

			waf:exec()
		}

		content_by_lua_block {
			local collections = ngx.ctx.lua_resty_waf.collections

			local res = {}

			res[1] = collections.TIME
			res[2] = collections.TIME_DAY
			res[3] = collections.TIME_EPOCH
			res[4] = collections.TIME_HOUR
			res[5] = collections.TIME_MIN
			res[6] = collections.TIME_MON
			res[7] = collections.TIME_SEC
			res[8] = collections.TIME_YEAR

			ngx.say(table.concat(res, "\n"))
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
16:21:59
13
684793319
16
21
09
59
1991
--- no_error_log
[error]

