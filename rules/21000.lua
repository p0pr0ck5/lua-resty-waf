-- HTTP Protocol Anomalies

local _M = {}

_M.version = "0.6.0"

_M.rules = {
	access = {
		{
			id = 21001,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "keys" },
				pattern = "host",
				operator = "NOT_CONTAINS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "No valid Host header"
		},
		{
			id = 21002,
			var = {
				type = "METHOD",
				pattern = "OPTIONS",
				operator = "NOT_EQUALS"
			},
			opts = { nolog = true },
			action = "CHAIN",
		},
		{
			id = 21003,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "keys" },
				pattern = "accept",
				operator = "NOT_CONTAINS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "No valid Accept header"
		},
		{
			id = 21004,
			var = {
				type = "METHOD",
				pattern = "OPTIONS",
				operator = "NOT_EQUALS"
			},
			opts = { nolog = true },
			action = "CHAIN",
		},
		{
			id = 21005,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "accept" },
				pattern = [=[^$]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Accept header has no value"
		},
		{
			id = 21006,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "keys" },
				pattern = "user-agent",
				operator = "NOT_CONTAINS"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "No valid User-Agent header"
		},
		{
			id = 21007,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "user-agent" },
				pattern = [=[^$]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "User-Agent header has no value"
		},
		{
			id = 21008,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "keys" },
				pattern = "content-type",
				operator = "NOT_CONTAINS"
			},
			opts = { nolog = true },
			action = "CHAIN",
		},
		{
			id = 21009,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "content-length" },
				pattern = [=[^0$]=],
				operator = "NOT_REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Request contains content, but missing Content-Type header"
		},
		{
			id = 21010,
			var = {
				type = "REQUEST_HEADERS",
				opts = { key = "specific", value = "host" },
				pattern = [=[^[\d.:]+$]=],
				operator = "REGEX"
			},
			opts = { score = 2 },
			action = "SCORE",
			description = "Host header contains an IP address"
		}
	}
}

return _M
