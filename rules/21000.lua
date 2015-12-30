-- HTTP Protocol Anomalies

local _M = {}

_M.version = "0.5.2"

local _rules = {
	{
		id = 21001,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "host",
			operator = "NOT_EXISTS"
		},
		opts = { score = 2 },
		action = "SCORE",
		description = "No valid Host header"
	},
	{
		id = 21002,
		var = {
			type = "HEADERS",
			opts = { key = "specific", value = "host" },
			pattern = [=[^$]=],
			operator = "REGEX"
		},
		opts = { score = 2 },
		action = "SCORE",
		description = "Host header has no value"
	},
	{
		id = 21003,
		var = {
			type = "METHOD",
			opts = nil,
			pattern = "OPTIONS",
			operator = "NOT_EQUALS"
		},
		opts = { nolog = true },
		action = "CHAIN",
	},
	{
		id = 21004,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "accept",
			operator = "NOT_EXISTS"
		},
		opts = { chainchild = true, chainend = true, score = 2 },
		action = "SCORE",
		description = "No valid Accept header"
	},
	{
		id = 21005,
		var = {
			type = "METHOD",
			opts = nil,
			pattern = "OPTIONS",
			operator = "NOT_EQUALS"
		},
		opts = { nolog = true },
		action = "CHAIN",
	},
	{
		id = 21006,
		var = {
			type = "HEADERS",
			opts = { key = "specific", value = "accept" },
			pattern = [=[^$]=],
			operator = "REGEX"
		},
		opts = { chainchild = true, chainend = true, score = 2 },
		action = "SCORE",
		description = "Accept header has no value"
	},
	{
		id = 21007,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "user-agent",
			operator = "NOT_EXISTS"
		},
		opts = { score = 2 },
		action = "SCORE",
		description = "No valid User-Agent header"
	},
	{
		id = 21008,
		var = {
			type = "HEADERS",
			opts = { key = "specific", value = "user-agent" },
			pattern = [=[^$]=],
			operator = "REGEX"
		},
		opts = { score = 2 },
		action = "SCORE",
		description = "User-Agent header has no value"
	},
	{
		id = 21009,
		var = {
			type = "HEADER_NAMES",
			opts = nil,
			pattern = "content-type",
			operator = "NOT_EXISTS"
		},
		opts = { nolog = true },
		action = "CHAIN",
	},
	{
		id = 21010,
		var = {
			type = "HEADERS",
			opts = { key = "specific", value = "content-length" },
			pattern = [=[^0$]=],
			operator = "NOT_REGEX"
		},
		opts = { chainchild = true, chainend = true, score = 2 },
		action = "SCORE",
		description = "Request contains content, but missing Content-Type header"
	},
	{
		id = 21011,
		var = {
			type = "HEADERS",
			opts = { key = "specific", value = "host" },
			pattern = [=[^[\d.:]+$]=],
			operator = "REGEX"
		},
		opts = { score = 2 },
		action = "SCORE",
		description = "Host header contains an IP address"
	}
}

function _M.rules()
	return _rules
end

return _M
