use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

repeat_each(3);
plan tests => repeat_each() * 7 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: DENY exits the phase with ngx.HTTP_FORBIDDEN in custom phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		}

		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("mode", "ACTIVE")
			waf:set_option("add_ruleset_string", "10100", [=[{"header_filter":[{"actions":{"disrupt":"DENY"},"id":"12345","operator":"REGEX","pattern":"bar","vars":[{"parse":["values",1],"type":"RESPONSE_HEADERS"}]}],"body_filter":[],"access":[]}]=])
			waf:exec({
				phase = "header_filter",
				collections = {
					RESPONSE_HEADERS = { ["X-Foo"] = "bar" }
				}
			})

			ngx.log(ngx.INFO, "We should not see this")
		}
	}
--- request
GET /t
--- error_code: 403
--- error_log
Rule action was DENY, so telling nginx to quit
--- no_error_log
[error]
We should not see this

=== TEST 2a: Access persistent storage via cosocket API in body_filter rules
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("storage_backend", "memcached")
			waf:set_option("add_ruleset", "body_storage")

--[[
rules for these tests:

SecAction "id:12345,nolog,pass,initcol:IP=%{REMOTE_ADDR},phase:1"

SecRule ARGS "@streq foo" "id:12346,pass,setvar:IP.hit=foo,phase:2"

SecRule ARGS "@streq bar" "id:12347,pass,setvar:!IP.hit"

SecRule IP:hit "@streq foo" "id:12348,deny,phase:4"
--]]

			waf:exec()
		}

		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec({
				phase = "header_filter",
				collections = {
					RESPONSE_HEADERS = {
						["X-Foo"] = "bar",
						["Content-Type"] = "text/plain",
					},
					STATUS = 200
				}
			})

			waf:exec({
				phase = "body_filter",
				collections = {
					RESPONSE_BODY = "hello, world"
				}
			})
		}
	}
--- request
GET /t?a=foo
--- error_code: 403
--- error_log
Initializing storage type memcached
Setting 127.0.0.1:HIT to foo
Persisting storage type memcached
Match of rule 12348
--- no_error_log
[error]
Deleting 127.0.0.1:HIT
Match of rule 12347

=== TEST 2b: Access persistent storage via cosocket API in body_filter rules
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local memcached_m = require "resty.memcached"
			local memcached   = memcached_m:new()

			memcached:connect(waf._storage_memcached_host, waf._storage_memcached_port)
			memcached:flush_all()

			waf:set_option("mode", "ACTIVE")
			waf:set_option("debug", true)
			waf:set_option("storage_backend", "memcached")
			waf:set_option("add_ruleset", "body_storage")
			waf:exec()
		}

		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec({
				phase = "header_filter",
				collections = {
					RESPONSE_HEADERS = {
						["X-Foo"] = "bar",
						["Content-Type"] = "text/plain",
					},
					STATUS = 200
				}
			})

			waf:exec({
				phase = "body_filter",
				collections = {
					RESPONSE_BODY = "hello, world"
				}
			})
		}
	}
--- request
GET /t?a=foo&foo=bar
--- error_code: 200
--- error_log
Initializing storage type memcached
Setting 127.0.0.1:HIT to foo
Deleting 127.0.0.1:HIT
Persisting storage type memcached
Match of rule 12347
--- no_error_log
[error]
Match of rule 12348

