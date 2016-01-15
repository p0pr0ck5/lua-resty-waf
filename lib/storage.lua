local _M = {}

_M.version = "0.5.2"

local logger = require("lib.log")
local util   = require("lib.util")

-- retrieve a given key from persistent storage
function _M.retrieve_persistent_var(FW, key)
	local shm = ngx.shared[FW._storage_zone]
	local var = shm:get(key)
	return var
end

-- wrapper to get persistent storage data
function _M.get_var(FW, key, collections)
	-- silently bail from rules that require persistent storage if no shm was configured
	if (not FW._storage_zone) then
		return
	end

	return _M.retrieve_persistent_var(FW, util.parse_dynamic_value(FW, key, collections))
end

-- add/update data to persistent storaage
function _M.set_var(FW, ctx, collections)
	-- silently bail from rules that require persistent storage if no shm was configured
	if (not FW._storage_zone) then
		return
	end

	local key = util.parse_dynamic_value(FW, ctx.rule_setvar_key, collections)
	local value = util.parse_dynamic_value(FW, ctx.rule_setvar_value, collections)
	local expire = ctx.rule_setvar_expire or 0

	logger.log(FW, "initially setting " .. ctx.rule_setvar_key .. " to " .. ctx.rule_setvar_value)

	local shm = ngx.shared[FW._storage_zone]

	-- values can have arithmetic operations performed on them
	local incr = ngx.re.match(value, [=[^([\+\-\*\/])(\d+)]=], FW._pcre_flags)

	if (incr) then
		local operator = incr[1]
		local newval = incr[2]
		local oldval = _M.retrieve_persistent_var(FW, key)

		if (not oldval) then
			oldval = 0
		end

		if (operator == "+") then
			value = oldval + newval
		elseif (operator == "-") then
			value = oldval - newval
		elseif (operator == "*") then
			value = oldval * newval
		elseif (operator == "/") then
			value = oldval / newval
		end
	end

	logger.log(FW, "actually setting " .. key .. " to " .. value)

	local ok = shm:safe_set(key, value, expire)

	if (not ok) then
		ngx.log(ngx.WARN, "Could not add key to persistent storage, increase the size of the lua_shared_dict " .. FW._storage_zone)
	end
end

return _M
