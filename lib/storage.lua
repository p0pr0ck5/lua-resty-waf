local _M = {}

_M.version = "0.7.1"

local cjson  = require("cjson")
local logger = require("lib.log")
local util   = require("lib.util")

function _M.initialize(waf, storage, col)
	if (not waf._storage_zone) then
		return
	end

	local altered, serialized, shm
	shm        = ngx.shared[waf._storage_zone]
	serialized = shm:get(col)
	altered    = false

	if (not serialized) then
		logger.log(waf, "Initializing an empty collection for " .. col)
		storage[col] = {}
	else
		local data = cjson.decode(serialized)

		-- because we're serializing out the contents of the collection
		-- we need to roll our own expire handling. lua_shared_dict's
		-- internal expiry can't act on individual collection elements
		for key in pairs(data) do
			if (not key:find("__", 1, true) and data["__expire_" .. key]) then
				logger.log(waf, "checking " .. key)
				if (data["__expire_" .. key] < ngx.time()) then
					logger.log(waf, "Removing expired key: " .. key)
					data["__expire_" .. key] = nil
					data[key] = nil
					altered = true
				end
			end
		end

		storage[col] = data
	end

	storage[col]["__altered"] = altered
end

function _M.set_var(waf, ctx, element, value)
	local col     = ctx.col_lookup[string.upper(element.col)]
	local key     = element.key
	local inc     = element.inc
	local storage = ctx.storage

	if (inc) then
		local existing = storage[col][key]

		if (existing and type(existing) ~= "number") then
			logger.fatal_fail("Cannot increment a value that was not previously a number")
		elseif (not existing) then
			logger.log(waf, "Incrementing a non-existing value")
			existing = 0
		end

		if (type(value) == "number") then
			value = value + existing
		else
			logger.log(waf, "Failed to increment a non-number, falling back to existing value")
			value = existing
		end
	end

	logger.log(waf, "Setting " .. col .. ":" .. key .. " to " .. value)

	-- save data to in-memory table
	-- data not in the TX col will be persisted at the end of the phase
	storage[col][key]         = value
	storage[col]["__altered"] = true
end

function _M.persist(waf, storage)
	if (not waf._storage_zone) then
		return
	end

	local shm = ngx.shared[waf._storage_zone]

	for col in pairs(storage) do
		if (col ~= 'TX') then
			logger.log(waf, 'Examining ' .. col)

			if (storage[col]["__altered"]) then
				local serialized = cjson.encode(storage[col])

				logger.log(waf, 'Persisting value: ' .. tostring(serialized))

				shm:set(col, serialized)
			else
				logger.log(waf, "Not persisting a collection that wasn't altered")
			end
		end
	end
end

return _M
