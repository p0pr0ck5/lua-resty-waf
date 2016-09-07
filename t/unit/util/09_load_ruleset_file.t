use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/t/?.lua;;";
	init_by_lua_block {
		if (os.getenv("LRW_COVERAGE")) then
			runner = require "luacov.runner"
			runner.tick = true
			runner.init({savestepsize = 50})
			jit.off()
		end
	}
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Load a ruleset file
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
			local util = require "resty.waf.util"

			local ruleset, err = util.load_ruleset_file("extra")

			ngx.say(type(ruleset))
			ngx.say(err)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
table
nil
--- no_error_log
[error]

=== TEST 2: Fail to load a non-existent ruleset
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
			local util = require "resty.waf.util"

			local parse, err = util.load_ruleset_file("dne")

			ngx.say(type(parse))
			ngx.say(err)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
could not find dne
--- no_error_log
[error]

=== TEST 3: Fail to load an invalid ruleset
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
			local util = require "resty.waf.util"

			local parse, err = util.load_ruleset_file("extra_broken")

			ngx.say(type(parse))
			ngx.print(err)
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
nil
could not decode {
--- no_error_log
[error]

