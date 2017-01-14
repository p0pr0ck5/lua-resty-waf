use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;";
	lua_package_cpath "$pwd/lib/?.lua;;";
};

our $log_prefix = qr{\d{4}/\d{2}/\d{2} (?:\d+:?){3} \[\w+\] \d{2,5}\#\d+: \*\d+ \[lua\] };

repeat_each(3);
plan tests => repeat_each() * 11 * blocks();

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Debug logs written as expected
--- http_config eval: $::HttpConfig
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()

			waf:set_option("debug", true)
			waf:exec()
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- more_headers
Accept: */*
User-Agent: testy mctesterson
--- request
GET /t?foo=bar
--- error_code: 200
--- error_log eval
[
	$::log_prefix,
	qr{waf\.lua:\d+: exec\(\): \[[0-9a-z]{20}\] Beginning run of phase access},
	qr{waf\.lua:\d+: exec\(\): \[[0-9a-z]{20}\] Beginning ruleset \d+_\w+},
	qr{waf\.lua:\d+: exec\(\): \[[0-9a-z]{20}\] Processing rule \d+},
	qr{waf\.lua:\d+: _process_rule\(\): \[[0-9a-z]{20}\] Checking for collection_key [A-Z]+\|[a-z]+,},
	qr{util\.lua:\d+: _parse_collection\(\): \[[0-9a-z]{20}\] Parse collection},
	qr{waf\.lua:\d+: _process_rule\(\): \[[0-9a-z]{20}\] Returning offset \d+},
	qr{waf\.lua:\d+: _process_rule\(\): \[[0-9a-z]{20}\] Returning offset nil},
	qr{storage\.lua:\d+: persist\(\): \[[0-9a-z]{20}\] Persisting storage type},
]
--- no_error_log
[error]

