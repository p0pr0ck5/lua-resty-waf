use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Specific (individual)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["specific"]({}, collection, "foo")
			ngx.say(specific)
		';
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
bar
--- no_error_log
[error]

=== TEST 2: Specific (table)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local specific   = lookup.parse_collection["specific"]({}, collection, "foo")
			for i in ipairs(specific) do
				ngx.say(specific[i])
			end
		';
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
bar
bat
--- no_error_log
[error]

=== TEST 3: Ignore (individual)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local ignore     = lookup.parse_collection["ignore"]({}, collection, "foo")
			for k, v in pairs(ignore) do
				ngx.say(v)
			end
		';
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
qux
--- no_error_log
[error]

=== TEST 4: Ignore (table)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local ignore     = lookup.parse_collection["ignore"]({}, collection, "foo")
			for k, v in pairs(ignore) do
				ngx.say(v)
			end
		';
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
qux
--- no_error_log
[error]

=== TEST 5: Keys (individual)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local keys       = lookup.parse_collection["keys"]({}, collection, "foo")
			for i in ipairs(keys) do
				ngx.say(keys[i])
			end
		';
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
foo
baz
--- no_error_log
[error]

=== TEST 6: Keys (table)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local keys       = lookup.parse_collection["keys"]({}, collection, "foo")
			for i in ipairs(keys) do
				ngx.say(keys[i])
			end
		';
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
foo
baz
--- no_error_log
[error]

=== TEST 7: Values (individual)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local values     = lookup.parse_collection["values"]({}, collection, "foo")
			for i in ipairs(values) do
				ngx.say(values[i])
			end
		';
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
bar
qux
--- no_error_log
[error]

=== TEST 8: Values (table)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local values     = lookup.parse_collection["values"]({}, collection, "foo")
			for i in ipairs(values) do
				ngx.say(values[i])
			end
		';
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
bar
bat
qux
--- no_error_log
[error]

=== TEST 9: All (individual)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local all        = lookup.parse_collection["all"]({}, collection, "foo")
			for i in ipairs(all) do
				ngx.say(all[i])
			end
		';
	}
--- request
GET /t?foo=bar&baz=qux
--- error_code: 200
--- response_body
foo
baz
bar
qux
--- no_error_log
[error]

=== TEST 10: All (table)
--- config
	location /t {
		content_by_lua '
			local lookup     = require "FreeWAF.lib.lookup"
			local collection = ngx.req.get_uri_args()
			local all        = lookup.parse_collection["all"]({}, collection, "foo")
			for i in ipairs(all) do
				ngx.say(all[i])
			end
		';
	}
--- request
GET /t?foo=bar&foo=bat&baz=qux
--- error_code: 200
--- response_body
foo
baz
bar
bat
qux
--- no_error_log
[error]

