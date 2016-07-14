use Test::Nginx::Socket::Lua;

repeat_each(3);
plan tests => repeat_each() * 3 * blocks() - 3;

no_shuffle();
run_tests();

__DATA__

=== TEST 1: Send a message to a TCP server
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local lookup  = require "resty.waf.lookup"

			waf:set_option("event_log_target", "socket")
			waf:set_option("event_log_target_host", "127.0.0.1")
			waf:set_option("event_log_target_port", 9001)
			waf:set_option("event_log_socket_proto", "tcp")
			waf:set_option("event_log_buffer_size", 32)

			lookup.write_log_events[waf._event_log_target](waf, "A message has been sent to a socket")
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- tcp_listen: 9001
--- tcp_reply
A response is sent
--- error_code: 200
--- tcp_query
"A message has been sent to a socket"
--- no_error_log
[error]

=== TEST 2: Delayed send - periodic flush
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local lookup  = require "resty.waf.lookup"

			waf:set_option("event_log_target", "socket")
			waf:set_option("event_log_target_host", "127.0.0.1")
			waf:set_option("event_log_target_port", 9001)
			waf:set_option("event_log_socket_proto", "tcp")
			waf:set_option("event_log_buffer_size", 64)
			waf:set_option("event_log_periodic_flush", 1)

			lookup.write_log_events[waf._event_log_target](waf, "A message has been sent to a socket")

			ngx.sleep(2)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- tcp_listen: 9001
--- tcp_reply
A response is sent
--- error_code: 200
--- tcp_query
"A message has been sent to a socket"
--- no_error_log
[error]

=== TEST 3: Stale buffer never sends
--- config
	location /t {
		access_by_lua '
			local lua_resty_waf = require "resty.waf"
			local waf           = lua_resty_waf:new()
			local lookup  = require "resty.waf.lookup"

			waf:set_option("event_log_target", "socket")
			waf:set_option("event_log_target_host", "127.0.0.1")
			waf:set_option("event_log_target_port", 9001)
			waf:set_option("event_log_socket_proto", "tcp")
			waf:set_option("event_log_buffer_size", 64)

			lookup.write_log_events[waf._event_log_target](waf, "A message has been sent to a socket")

			ngx.sleep(2)
		';

		content_by_lua 'ngx.exit(ngx.HTTP_OK)';
	}
--- request
GET /t
--- tcp_listen: 9001
--- tcp_reply
A response is sent
--- error_code: 200
--- no_error_log
[error]

