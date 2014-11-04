local rs_30000 = {}

local _rules = {
	{
		id = "30001",
		vars = {
			{
				type = "HTTP_VERSION",
				opts = { { nil } },
				pattern = 1.1,
				operator = "NOT_EQUALS",
			}
		},
		action = "LOG",
		description = "Only HTTP/1.1 is allowed"
	},
	{
		id = "30002",
		vars = {
			{
				type = "URI",
				opts = { { nil } },
				pattern = [=[\.(?:(?:(?:c(?:o(?:nf(?:ig)?|m)|s(?:proj|r)?|dx|er|fg|md)|p(?:rinter|ass|db|ol|wd)|v(?:b(?:proj|s)?|sdisco)|a(?:s(?:ax?|cx)|xd)|d(?:bf?|at|ll|os)|i(?:d[acq]|n[ci])|ba(?:[kt]|ckup)|res(?:ources|x)|l(?:icx|nk|og)|s(?:ql|ys)|webinfo|ht[rw]|xs[dx]|key|mdb|old)))$]=],
				operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Disallowed file extension",
	},
}

function rs_30000.rules()
	return _rules
end

return rs_30000
