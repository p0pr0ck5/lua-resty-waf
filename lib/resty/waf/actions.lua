local _M = {}

local logger = require "resty.waf.log"

_M.version = "0.8.1"

_M.alter_actions = {
	ACCEPT = true,
	DENY   = true,
}

_M.lookup = {
	ACCEPT = function(waf, ctx)
		logger.log(waf, "Rule action was ACCEPT, so ending this phase with ngx.OK")
		if (waf._mode == "ACTIVE") then
			ngx.exit(ngx.OK)
		end
	end,
	CHAIN = function(waf, ctx)
		logger.log(waf, "Chaining (pre-processed)")
	end,
	SCORE = function(waf, ctx)
		logger.log(waf, "Score isn't a thing anymore, see TX.anomaly_score")
	end,
	DENY = function(waf, ctx)
		logger.log(waf, "Rule action was DENY, so telling nginx to quit")
		if (waf._mode == "ACTIVE") then
			ngx.exit(waf._deny_status)
		end
	end,
	IGNORE = function(waf)
		logger.log(waf, "Ignoring rule for now")
	end,
}

return _M
