use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Handle a fatal failure
--- http_config
	init_by_lua '
		logger = require "lib.log"
	';
--- config
	location /t {
		access_by_lua '
			logger.fatal_fail("We have encountered a fatal failure!")
		';
	}
--- request
GET /t
--- error_code: 500
--- error_log eval
["in function 'fatal_fail'", qr/\[error\].*We have encountered a fatal failure!/]

=== TEST 2: Handle a fatal failure with warn error log level
--- http_config
	init_by_lua '
		logger = require "lib.log"
	';
--- config
	location /t {
		access_by_lua '
			logger.fatal_fail("We have encountered a fatal failure!")
		';
	}
--- log_level
warn
--- request
GET /t
--- error_code: 500
--- error_log eval
["in function 'fatal_fail'", qr/\[error\].*We have encountered a fatal failure!/]

