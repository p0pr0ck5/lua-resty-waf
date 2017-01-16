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

=== TEST 1: hex_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local util   = require "resty.waf.util"
			local value  = "48656c6c6f2c20776f726c6421"
			ngx.say(util.hex_decode(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
Hello, world!
--- no_error_log
[error]

=== TEST 2: invalid hex_decode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local util   = require "resty.waf.util"
			local value  = "this is not hex"
			ngx.say(util.hex_decode(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
this is not hex
--- no_error_log
[error]

=== TEST 3: hex_encode
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua '
			local util   = require "resty.waf.util"
			local value  = "Hello, world!"
			ngx.say(util.hex_encode(value))
		';
	}
--- request
GET /t
--- error_code: 200
--- response_body
48656c6c6f2c20776f726c6421
--- no_error_log
[error]

