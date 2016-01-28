-- Score threshold

local _M = {}

_M.version = "0.6.0"

_M.rules = {
	access = {
		{
			id = 99001,
			var = {
				type = "SCORE",
				pattern = "%{SCORE_THRESHOLD}",
				operator = "GREATER"
			},
			opts = { parsepattern = true },
			action = "DENY",
			description = "Request score greater than score threshold"
		}
	},
	header_filter = {
		{
			id = 99002,
			var = {
				type = "SCORE",
				pattern = "%{SCORE_THRESHOLD}",
				operator = "GREATER"
			},
			opts = { parsepattern = true },
			action = "DENY",
			description = "Request score greater than score threshold"
		}
	}
}

return _M
