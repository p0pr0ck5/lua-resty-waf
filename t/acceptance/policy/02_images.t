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

=== TEST 1: Skip whitelisting of non-passive requests
--- http_config eval: $::HttpConfig
--- config
	access_by_lua '
		local lua_resty_waf = require "resty.waf"
		local waf           = lua_resty_waf:new()

		waf:set_option("debug", true)
		waf:set_option("mode", "ACTIVE")
		waf:exec()
	';

	location /t {
		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request
POST /t
foo=bar
--- error_code: 200
--- error_log
Match of rule 11003
--- no_error_log
[error]

=== TEST 2: Whitelist .jpg
--- http_config eval: $::HttpConfig
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
GET /foo.jpg
--- error_code: 404
--- error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 3: Whitelist .jpeg
--- http_config eval: $::HttpConfig
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
GET /foo.jpeg
--- error_code: 404
--- error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 4: Whitelist .png
--- http_config eval: $::HttpConfig
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
GET /foo.png
--- error_code: 404
--- error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 5: Whitelist .gif
--- http_config eval: $::HttpConfig
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
GET /foo.gif
--- error_code: 404
--- error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 6: Whitelist .ico
--- http_config eval: $::HttpConfig
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
GET /foo.ico
--- error_code: 404
--- error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 7: Do not whitelist unmatched extension (.tiff)
--- http_config eval: $::HttpConfig
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
GET /foo.tiff
--- error_code: 404
--- no_error_log
Match of rule 11004
Rule action was ACCEPT

=== TEST 8: Do not whitelist non-final extension
--- http_config eval: $::HttpConfig
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
GET /foo.jpg.exe
--- error_code: 404
--- no_error_log
Match of rule 11004
Rule action was ACCEPT

