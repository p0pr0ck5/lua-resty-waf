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

=== TEST 1: ACCEPT is an alter action
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local actions = require "resty.waf.actions"
			local alter_actions = actions.alter_actions
			for action in pairs(alter_actions) do
				ngx.say(action)
			end
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- response_body_like
ACCEPT
--- no_error_log
[error]

=== TEST 2: DENY is an alter action
--- request
GET /t
--- error_code: 200
--- response_body_like
DENY
--- no_error_log
[error]

=== TEST 3: IGNORE is not an alter action
--- request
GET /t
--- error_code: 200
--- response_body_unlike
IGNORE
--- no_error_log
[error]

=== TEST 4: CHAIN is not an alter action
--- request
GET /t
--- error_code: 200
--- response_body_unlike
CHAIN
--- no_error_log
[error]

=== TEST 5: SCORE is not an alter action
--- request
GET /t
--- error_code: 200
--- response_body_unlike
SCORE
--- no_error_log
[error]

=== TEST 5: DROP is an alter action
--- request
GET /t
--- error_code: 200
--- response_body_like
DROP
--- no_error_log
[error]
