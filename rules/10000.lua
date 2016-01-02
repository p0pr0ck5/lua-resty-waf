-- User-defined ACLs

local _M = {}

_M.version = "0.5.2"

_M.rules = {
	{
		id = 10001,
		var = {
			type = "WHITELIST",
			pattern = "%{IP}",
			operator = "EXISTS"
		},
		opts = { parsepattern = true, nolog = true },
		action = "ACCEPT",
		description = "User-defined whitelist"
	},
	{
		id = 10002,
		var = {
			type = "BLACKLIST",
			pattern = "%{IP}",
			operator = "EXISTS"
		},
		opts = { parsepattern = true, nolog = true },
		action = "DENY",
		description = "User-defined blacklist"
	}
}

return _M
