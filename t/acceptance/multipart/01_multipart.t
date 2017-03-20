use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

our $mock_upload = qq{\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="file1"; filename="a.txt"\r
Content-Type: text/plain\r
\r
Hello, world\r\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="test"\r
\r
value\r\n-----------------------------820127721219505131303151179--\r
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Execute with a file upload
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
All good!
--- no_error_log
[error]

=== TEST 2: Execute with a ruleset inspecting FILES
--- http_config eval
$::HttpConfig . qq#
	init_by_lua_block {
		local waf = require "resty.waf"
		waf.global_rulesets = {}
	}

	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/multipart.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "multipart.rules")
			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t?id=12345a# . $::mock_upload
--- error_code: 403
--- error_log
Match of rule 12345
--- no_error_log
[error]

=== TEST 3: Execute with a ruleset inspecting FILES_NAMES
--- http_config eval
$::HttpConfig . qq#
	init_by_lua_block {
		local waf = require "resty.waf"
		waf.global_rulesets = {}
	}

	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/multipart.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "multipart.rules")
			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t?id=12346a# . $::mock_upload
--- error_code: 403
--- error_log
Match of rule 12346
--- no_error_log
[error]

=== TEST 4: Execute with a ruleset inspecting FILES_COMBINED_SIZE
--- http_config eval
$::HttpConfig . qq#
	init_by_lua_block {
		local waf = require "resty.waf"
		waf.global_rulesets = {}
	}

	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/multipart.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "multipart.rules")
			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t?id=12347a# . $::mock_upload
--- error_code: 403
--- error_log
Match of rule 12347
--- no_error_log
[error]

=== TEST 5: Execute with a ruleset inspecting FILES_SIZES
--- http_config eval
$::HttpConfig . qq#
	init_by_lua_block {
		local waf = require "resty.waf"
		waf.global_rulesets = {}
	}

	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/multipart.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "multipart.rules")
			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t?id=12348a# . $::mock_upload
--- error_code: 403
--- error_log
Match of rule 12348
--- no_error_log
[error]

=== TEST 6: Execute with a ruleset inspecting FILES_TMP_CONTENT
--- http_config eval
$::HttpConfig . qq#
	init_by_lua_block {
		local waf = require "resty.waf"
		waf.global_rulesets = {}
	}

	init_worker_by_lua_block {
		local waf = require "resty.waf"
		waf.load_secrules("$::pwd/t/rules/multipart.rules")
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset", "multipart.rules")
			waf:exec()
		}

		content_by_lua_block { ngx.say("All good!") }
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t?id=12349a# . $::mock_upload
--- error_code: 403
--- error_log
Match of rule 12349
--- no_error_log
[error]

