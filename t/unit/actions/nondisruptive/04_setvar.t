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

=== TEST 1: setvar calls storage.set_var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local actions = require "resty.waf.actions"
			local storage = require "resty.waf.storage"
			local util    = require "resty.waf.util"

			util.parse_dynamic_value = function(waf, key, collections)
				return collections[key]
			end

			storage.set_var = function(waf, ctx, data, value)
				ngx.log(ngx.DEBUG, "Called storage.set_var with data.value " .. data.value .. " and value " .. value)
			end

			actions.nondisruptive_lookup["setvar"]({}, { value = "foo", time = "foo" }, {}, { foo = "dynamic-foo" })
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Called storage.set_var with data.value foo and value dynamic-foo
--- no_error_log
[error]

=== TEST 2: setvar calls storage.set_var (macro'd key)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local actions = require "resty.waf.actions"
			local storage = require "resty.waf.storage"
			local util    = require "resty.waf.util"

			util.parse_dynamic_value = function(waf, key, collections)
				return collections[key]
			end

			storage.set_var = function(waf, ctx, data, value)
				ngx.log(ngx.DEBUG, "Called storage.set_var with data.key " .. data.key)
			end

			actions.nondisruptive_lookup["setvar"]({}, { value = "foo", key = "bar" }, {}, { foo = "dynamic-foo", bar = "dynamic-bar" })
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request
GET /t
--- error_code: 200
--- error_log
Called storage.set_var with data.key dynamic-bar
--- no_error_log
[error]

