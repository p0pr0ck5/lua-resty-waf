use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

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

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: FILES collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local request = require "resty.waf.request"

			local collections = {}

			request.parse_request_body(
				{
					_pcre_flags = 'joi',
					_process_multipart_body = true,
				},
				{
					["content-type"] = ngx.req.get_headers()['content-type']
				},
				collections
			)

			ngx.say(collections.FILES[1])
			ngx.say(collections.FILES[2])
		}
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
a.txt
nil
--- no_error_log
[error]

=== TEST 2: FILES_NAMES collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local request = require "resty.waf.request"

			local collections = {}

			request.parse_request_body(
				{
					_pcre_flags = 'joi',
					_process_multipart_body = true,
				},
				{
					["content-type"] = ngx.req.get_headers()['content-type']
				},
				collections
			)

			ngx.say(collections.FILES_NAMES[1])
			ngx.say(collections.FILES_NAMES[2])
		}
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
file1
test
--- no_error_log
[error]

=== TEST 3: FILES_SIZES collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local request = require "resty.waf.request"

			local collections = {}

			request.parse_request_body(
				{
					_pcre_flags = 'joi',
					_process_multipart_body = true,
				},
				{
					["content-type"] = ngx.req.get_headers()['content-type']
				},
				collections
			)

			ngx.say(collections.FILES_SIZES[1])
			ngx.say(collections.FILES_SIZES[2])
		}
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
12
5
--- no_error_log
[error]

=== TEST 4: FILES_COMBINED_SIZE collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local request = require "resty.waf.request"

			local collections = {}

			request.parse_request_body(
				{
					_pcre_flags = 'joi',
					_process_multipart_body = true,
				},
				{
					["content-type"] = ngx.req.get_headers()['content-type']
				},
				collections
			)

			ngx.say(collections.FILES_COMBINED_SIZE)
		}
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
17
--- no_error_log
[error]

=== TEST 5: FILES_TMP_CONTENT collections variable
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua_block {
			local request = require "resty.waf.request"

			local collections = {}

			request.parse_request_body(
				{
					_pcre_flags = 'joi',
					_process_multipart_body = true,
				},
				{
					["content-type"] = ngx.req.get_headers()['content-type']
				},
				collections
			)

			ngx.say(collections.FILES_TMP_CONTENT.file1)
			ngx.say(collections.FILES_TMP_CONTENT.test)
		}
	}
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
q#POST /t# . $::mock_upload
--- error_code: 200
--- response_body
Hello, world
value
--- no_error_log
[error]

