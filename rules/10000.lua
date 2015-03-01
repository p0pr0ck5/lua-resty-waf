-- Local Policy - Whitelisting

local _M = {}

_M.version = "0.4"

local _rules = {
	{
		id = 10001,
		var  = {
			type = "METHOD",
			opts = nil,
			pattern = [=[^(?:GET|HEAD)$]=],
			operator = "REGEX"
		},
		opts = { nolog = true },
		action = "CHAIN",
		description = "Ignore passive requests with no arguments"
	},
	{
		id = 10002,
		var = {
			type = "REQUEST_ARGS",
			opts = { key = "all" },
			pattern = [=[.*]=],
			operator = "NOT_REGEX",
		},
		opts = { chainchild = true, chainend = true, nolog = true },
		action = "ACCEPT",
		description = "Ignore passive requests with no arguments"
	},
	{
		id = 10003,
		var = {
			type = "METHOD",
			opts = nil,
			pattern = [=[^(?:GET|HEAD)$]=],
			operator = "NOT_REGEX"
		},
		opts = { nolog = true },
		action = "SKIP",
		description = "Skip whitelisting of some extensions for non-passive requests"
	},
	{
		id = 10004,
		var = {
			type = "URI",
			opts = nil,
			pattern = [=[\.(?:(?:jpe?|pn)g|gif|ico)$]=],
			operator = "REGEX"
		},
		opts = { nolog = true },
		action = "ACCEPT",
		description = "Whitelisting extensions - images"
	},
	{
		id = 10005,
		var = {
			type = "URI",
			opts = nil,
			pattern = [=[\.(?:doc|pdf|txt|xls)$]=],
			operator = "REGEX"
		},
		opts = { nolog = true },
		action = "ACCEPT",
		description = "Whitelisting extensions - documents"
	},
	{
		id = 10006,
		var = {
			type = "URI",
			opts = nil,
			pattern = [=[\.(?:(?:cs|j)s|html?)$]=],
			operator = "REGEX"
		},
		opts = { nolog = true },
		action = "ACCEPT",
		description = "Whitelisting extensions - HTML"
	},
	{
		id = 10007,
		var = {
			type = "URI",
			opts = nil,
			pattern = [=[\.(?:mp(?:e?g|(?:3|4))|avi|flv|swf|wma)$]=],
			operator = "REGEX"
		},
		opts = { skipend = true, nolog = true },
		action = "ACCEPT",
		description = "Whitelisting extensions - media"
	},
}

function _M.rules()
	return _rules
end

return _M
