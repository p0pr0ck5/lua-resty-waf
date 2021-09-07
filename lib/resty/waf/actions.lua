local _M = {}

local base    = require "resty.waf.base"
local logger  = require "resty.waf.log"
local storage = require "resty.waf.storage"
local util    = require "resty.waf.util"

_M.version = base.version

_M.alter_actions = {
	DENY   = true,
	DROP   = true,
}

_M.disruptive_lookup = {
	ACCEPT = function(waf, ctx)
		--_LOG_"Rule action was ACCEPT, so ending this phase with ngx.OK"
		if waf._mode == "ACTIVE" then
			ngx.exit(ngx.OK)
		end
	end,
	CHAIN = function(waf, ctx)
		--_LOG_"Chaining (pre-processed)"
	end,
	DENY = function(waf, ctx)
		--_LOG_"Rule action was DENY, so telling nginx to quit"
		if waf._mode == "ACTIVE" then
			ngx.exit(ctx.rule_status or waf._deny_status)
		end
	end,
	DROP = function(waf, ctx)
		--_LOG_"Rule action was DROP, ending eith ngx.HTTP_CLOSE"
		if waf._mode == "ACTIVE" then
			ngx.exit(ngx.HTTP_CLOSE)
		end
	end,
	IGNORE = function(waf)
		--_LOG_"Ignoring rule for now"
	end,
	SCORE = function(waf, ctx)
		--_LOG_"Score isn't a thing anymore, see TX.anomaly_score"
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

		--_LOG_"Initializing " .. col .. " as " .. parsed

		storage.initialize(waf, ctx.storage, parsed)
		ctx.col_lookup[col] = parsed
		collections[col]    = ctx.storage[parsed]
	end,
	setvar = function(waf, data, ctx, collections)
		data.key    = util.parse_dynamic_value(waf, data.key, collections)
		local value = util.parse_dynamic_value(waf, data.value, collections)

		storage.set_var(waf, ctx, data, value)
	end,
	sleep = function(waf, time)
		--_LOG_"Sleeping for " .. time

		ngx.sleep(time)
	end,
	status = function(waf, status, ctx)
		--_LOG_"Overriding status from " .. waf._deny_status .. " to " .. status

		ctx.rule_status = status
	end,
	rule_remove_id = function(waf, rule)
		--_LOG_"Runtime ignoring rule " .. rule

		waf._ignore_rule[rule] = true
	end,
	rule_remove_by_meta = function(waf, data, ctx)
		--_LOG_"Runtime ignoring rules by meta"

		-- this lookup table holds
		local meta_rules = waf._meta_exception.meta_ids[ctx.id]

		if not meta_rules then return end

		for i, id in ipairs(meta_rules) do
			--_LOG_"Runtime ignoring rule " .. id
			waf._ignore_rule[id] = true
		end
	end,
	mode_update = function(waf, mode)
		--_LOG_"Overriding mode from " .. waf._mode .. " to " .. mode

		waf._mode = mode
	end,
}

return _M
