use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

our $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Equal char in filename
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request eval
qq{POST /t\n----------397236876\r
Content-Disposition: form-data; name="fileRap"; filename="file=.txt"\r
Content-Type: text/plain\r
\r
555-555-0199\@example.com\r
\r\n----------397236876--\r
}
--- more_headers
Content-Type: multipart/form-data; boundary=--------397236876
--- error_code: 200
--- error_log
Match of rule 920120
--- no_error_log
[error]

=== TEST 2: Legacy bypass regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request eval
qq{POST /t\n-----------------------------627652292512397580456702590\r
Content-Disposition: form-data; name=x'';filename="'';name=contact.txt;"'\r
Content-Type: text/plain\r
\r
email: security\@modsecurity.org\r
\r
\r\n-----------------------------627652292512397580456702590\r
Content-Disposition: form-data; name="note"'\r
\r
Contact info.\r
\r\n-----------------------------627652292512397580456702590--\r
}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------627652292512397580456702590
--- error_log
Match of rule 920120
--- no_error_log
[error]

=== TEST 3: Legacy bypass regression
--- http_config eval
$::HttpConfig . qq#
	init_worker_by_lua_block {
		local waf = require "resty.waf"

		local opts = {
			path = "$::pwd/rules/",
			loose = true -- loose for ctl:forceRequestBodyVariable in 920420
		}

		waf.load_secrules("$::pwd/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf", opts)
		waf.init()
	}
#
--- config
	location /t {
		access_by_lua_block {
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:set_option("add_ruleset", "REQUEST-920-PROTOCOL-ENFORCEMENT.conf")
			waf:set_option("ignore_rule", '920450')
			waf:exec()
		}

		content_by_lua_block {ngx.exit(ngx.HTTP_OK)}
	}
--- request eval
qq{POST /t\n-----------------------------265001916915724\r
Content-Disposition: form-data; name="fi;le"; filename="test"\r
Content-Type: application/octet-stream'\r
\r
Rotem & Ayala\r
\r
\r\n-----------------------------265001916915724\r
Content-Disposition: form-data; name="name"\r
\r
tt2\r
\r
\r\n-----------------------------265001916915724\r
Content-Disposition: form-data; name="B1"\r
\r
Submit\r
\r
\r\n-----------------------------265001916915724--
}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------265001916915724
--- error_log
Match of rule 920120
--- no_error_log
[error]

