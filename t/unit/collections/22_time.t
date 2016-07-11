use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks();

add_response_body_check(sub {
	my ($block, $body, $req_idx, $repeated_req_idx, $dry_run) = @_;

	my $name = $block->name;

	my $epoch = time;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$year += 1900;

	SKIP: {
		skip "$name - tests skipped due to $dry_run", 1 if $dry_run;

		is(
			$body,
			sprintf("%d:%d:%d\n%02d\n%d\n%d\n%d\n%02d\n%d\n%d\n",
				$hour, $min, $sec, $mday, $epoch, $hour, $min, $mon + 1, $sec, $year),
			"$name - TIME collection elements are correct (req $repeated_req_idx)"
		);
	}
});

no_shuffle();
run_tests();

__DATA__

=== TEST 1: TIME collections variable
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "waf"
			local waf           = lua_resty_waf:new()

			waf:exec()
		';

		content_by_lua '
			local collections = ngx.ctx.collections

			local res = {}

			res[1] = collections.TIME
			res[2] = collections.TIME_DAY
			res[3] = collections.TIME_EPOCH
			res[4] = collections.TIME_HOUR
			res[5] = collections.TIME_MIN
			res[6] = collections.TIME_MON
			res[7] = collections.TIME_SEC
			res[8] = collections.TIME_YEAR

			ngx.say(table.concat(res, "\\n"))
		';
	}
--- request
GET /t
--- error_code: 200
--- no_error_log
[error]

