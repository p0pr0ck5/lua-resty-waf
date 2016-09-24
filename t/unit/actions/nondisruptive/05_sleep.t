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

=== TEST 1: sleep calls ngx.sleep
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local actions = require "resty.waf.actions"

			ngx.sleep = function(time)
				ngx.say("Slept for " .. time .. " seconds")
			end

			actions.nondisruptive_lookup["sleep"]({ _debug = true, _debug_log_level = ngx.INFO }, 5)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
Slept for 5 seconds
--- error_log
Sleeping for 5
--- no_error_log
[error]

