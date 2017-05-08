use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 4 * blocks() - 6;

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

check_accum_error_log();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Ignore an element that would have led to a match
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "bar",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?bar=foo
--- error_code: 200
--- error_log
Checking for collection_key REQUEST_ARGS|values|true|ignore,bar|nil
--- no_error_log
[error]
Match of rule 12345

=== TEST 2: Ignore an element that would not have led to a match (1/2)
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "bar",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?baz=foo
--- error_code: 403
--- error_log
Checking for collection_key REQUEST_ARGS|values|true|ignore,bar|nil
Match of rule 12345
--- no_error_log
[error]

=== TEST 3: Ignore an element that would not have led to a match (2/2)
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "bar",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?bar=foo&baz=foo
--- error_code: 403
--- error_log
Checking for collection_key REQUEST_ARGS|values|true|ignore,bar|nil
Match of rule 12345
--- no_error_log
[error]

=== TEST 4: Ignore an element as a regex
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "ba.*",
					action = "regex"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?battt=foo
--- error_code: 200
--- error_log
Checking for collection_key REQUEST_ARGS|values|true|regex,ba.*|nil
--- no_error_log
[error]
Match of rule 12345

=== TEST 5: Ignore multiple elements
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = { "bar", "bat" },
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?bat=foo&bar=foo
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 12345

=== TEST 6: Ignore an element not provided in the rule
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "TIME",
					elts   = "foo",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?battt=foo
--- error_code: 403
--- error_log
Match of rule 12345
TIME undefined in rule 12345
--- no_error_log
[error]

=== TEST 7: Ignore an elemenent in a rule already containing ignores (1/2)
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "foo",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			--waf:sieve_rule("12346", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?foo=baz&bar=baz
--- error_code: 403
--- error_log
Match of rule 12346
--- no_error_log
[error]

=== TEST 8: Ignore an elemenent in a rule already containing ignores (2/2)
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "foo",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12346", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?foo=baz&baz=bat
--- error_code: 200
--- error_log
--- no_error_log
[error]
Match of rule 12346

=== TEST 9: Sieve multiple rules
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves_a = {
				{
					type   = "ARGS",
					elts   = "bar",
					action = "ignore"
				}
			}
			local sieves_b = {
				{
					type   = "ARGS",
					elts   = "foo",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves_a)
			waf:sieve_rule("12346", sieves_b)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t?bar=foo&foo=baz
--- error_code: 200
--- error_log
Checking for collection_key REQUEST_ARGS|values|true|ignore,foo|nil
Checking for collection_key REQUEST_ARGS|values|true|ignore,bar|nil
--- no_error_log
[error]
Match of rule 12346

=== TEST 9: Sieve does not affect another context
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/sieve.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local sieves = {
				{
					type   = "ARGS",
					elts   = "bar",
					action = "ignore"
				}
			}

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:sieve_rule("12345", sieves)
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
	location /s {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "sieve.rules")
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request eval
["GET /t?bar=foo", "GET /s?bar=foo"]
--- error_code eval
[200, 403]
--- error_log
--- no_error_log
[error]

