use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 6 * blocks() - 6;

check_accum_error_log();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Show the design of the resource
--- http_config
	lua_shared_dict shm 10m;
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=bar", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["Set key 'foo'!\n", "shm:foo is set as: 'bar'\n"]

=== TEST 2: Benign request is not caught in SIMULATE mode
--- http_config
	lua_shared_dict shm 10m;
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=bar", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["Set key 'foo'!\n", "shm:foo is set as: 'bar'\n"]
--- no_error_log
"id":99001

=== TEST 3: Benign request is not caught in ACTIVE mode
--- http_config
	lua_shared_dict shm 10m;
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=bar", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["Set key 'foo'!\n", "shm:foo is set as: 'bar'\n"]
--- no_error_log
"id":99001

=== TEST 4: Malicious request exploits stored XSS vulnerability
--- http_config
	lua_shared_dict shm 10m;
--- config
	location /t {
		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=<script>alert(1)</script>", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["Set key 'foo'!\n", "shm:foo is set as: '<script>alert(1)</script>'\n"]
--- no_error_log
"id":99001

=== TEST 5: Malicious request is logged in SIMULATE mode
--- http_config
	lua_shared_dict shm 10m;
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:exec()
		';

		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=<script>alert(1)</script>", "GET /s"]
--- error_code eval
[200, 200]
--- response_body eval
["Set key 'foo'!\n", "shm:foo is set as: '<script>alert(1)</script>'\n"]
--- error_log
"id":99001

=== TEST 6: Malicious request is blocked in ACTIVE mode
--- http_config
	lua_shared_dict shm 10m;
	init_by_lua '
		local FW = require "fw"
		FW.init()
	';
--- config
	location /t {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua '
			local args = ngx.req.get_uri_args()
			local shm  = ngx.shared.shm

			shm:set("foo", args.foo)
			ngx.say("Set key \'foo\'!")
		';
	}

	location /s {
		access_by_lua '
			FreeWAF = require "fw"
			local fw = FreeWAF:new()

			fw:set_option("debug", true)
			fw:set_option("mode", "ACTIVE")
			fw:exec()
		';

		content_by_lua '
			local shm = ngx.shared.shm
			local foo = shm:get("foo")

			ngx.say("shm:foo is set as: \'" .. tostring(foo) .. "\'")
		';
	}
--- request eval
["GET /t?foo=<script>alert(1)</script>", "GET /s"]
--- error_code eval
[403, 200]
--- response_body eval
[qr/403 Forbidden/, "shm:foo is set as: 'nil'\n"]
--- response_body_unlike
["Set key 'foo'!", <script>alert\(1\)</script>]
--- error_log
"id":99001

