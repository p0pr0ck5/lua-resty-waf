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

=== TEST 1: expirevar calls storage.expire_var
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local actions = require "resty.waf.actions"
			local storage = require "resty.waf.storage"
			local util    = require "resty.waf.util"

			util.parse_dynamic_value = function(waf, key, collections)
				return collections[key]
			end

			storage.expire_var = function(waf, ctx, data, time)
				ngx.log(ngx.DEBUG, "Called storage.expire_var with data.value " .. data.value .. " and time " .. time)
			end

			actions.nondisruptive_lookup["expirevar"]({}, { value = "foo", time = "foo" }, {}, { foo = 5 })
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- error_code: 200
--- error_log
Called storage.expire_var with data.value foo and time 5
--- no_error_log
[error]

