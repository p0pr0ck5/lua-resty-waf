local _M = {}

local logger  = require "resty.waf.log"
local storage = require "resty.waf.storage"
local util    = require "resty.waf.util"

_M.version = "0.8.1"

_M.alter_actions = {
	ACCEPT = true,
	DENY   = true,
}

_M.disruptive_lookup = {
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

_M.nondisruptive_lookup = {
	deletevar = function(waf, data, ctx, collections)
		storage.delete_var(waf, ctx, data)
	end,
	expirevar = function(waf, data, ctx, collections)
		local time = util.parse_dynamic_value(waf, data.time, collections)

		storage.expire_var(waf, ctx, data, time)
	end,
	initcol = function(waf, data, ctx, collections)
		local col    = data.col
		local value  = data.value
		local parsed = util.parse_dynamic_value(waf, value, collections)

		logger.log(waf, "Initializing " .. col .. " as " .. parsed)

		storage.initialize(waf, ctx.storage, parsed)
		ctx.col_lookup[col] = parsed
		collections[col]    = ctx.storage[parsed]
	end,
	setvar = function(waf, data, ctx, collections)
		local value = util.parse_dynamic_value(waf, data.value, collections)

		storage.set_var(waf, ctx, data, value)
	end,
}

return _M
