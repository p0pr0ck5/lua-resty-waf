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

=== TEST 1: Define custom collections in a standard phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.foo)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
access
bar
--- no_error_log
[error]

=== TEST 2: Define custom collections in a standard phase (collections overriden)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
access
nil
--- no_error_log
[error]

=== TEST 3: Define custom collections in a custom phase
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				phase = "header_filter",
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.foo)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
header_filter
bar
--- no_error_log
[error]

=== TEST 4: Define custom collections in a custom phase (existing collections not overriden from separate phase)
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

			local opts = {
				phase = "header_filter",
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
header_filter
/t
--- no_error_log
[error]

=== TEST 5: Define custom collections in a custom phase (existing collections not overriden from same phase)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:exec()

			local opts = {
				phase = "header_filter",
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
			ngx.say(ctx.collections.foo)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
header_filter
/t
bar
--- no_error_log
[error]

=== TEST 5: Define custom collections in a custom phase (existing collections not overriden from same custom phase)
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			local opts = {
				phase = "access"
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
			ngx.say(ctx.collections.foo)

			opts = {
				phase = "header_filter",
				collections = {
					foo = "bar"
				}
			}

			waf:exec(opts)

			local ctx = ngx.ctx.lua_resty_waf

			ngx.say(ctx.phase)
			ngx.say(ctx.collections.URI)
			ngx.say(ctx.collections.foo)
		}
	}
--- request
GET /t
--- error_code: 200
--- response_body
access
/t
nil
header_filter
/t
bar
--- no_error_log
[error]

