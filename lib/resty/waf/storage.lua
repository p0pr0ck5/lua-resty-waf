local _M = {}

_M.version = "0.9"

local cjson  = require "cjson"
local logger = require "resty.waf.log"
local util   = require "resty.waf.util"

local string_upper = string.upper

local _valid_backends = { dict = true, memcached = true, redis = true }

function _M.initialize(waf, storage, col)
	local backend   = waf._storage_backend
	if (not util.table_has_key(backend, _valid_backends)) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	local backend_m = require("resty.waf.storage." .. backend)

	--_LOG_"Initializing storage type " .. backend

	backend_m.initialize(waf, storage, col)
end

function _M.set_var(waf, ctx, element, value)
	local col     = ctx.col_lookup[string_upper(element.col)]
	local key     = element.key
	local inc     = element.inc
	local storage = ctx.storage

	if (inc) then
		local existing = storage[col][key]

		if (existing and type(existing) ~= "number") then
			logger.fatal_fail("Cannot increment a value that was not previously a number")
		elseif (not existing) then
			--_LOG_"Incrementing a non-existing value"
			existing = 0
		end

		if (type(value) == "number") then
			value = value + existing
		else
			--_LOG_"Failed to increment a non-number, falling back to existing value"
			value = existing
		end
	end

	--_LOG_"Setting " .. col .. ":" .. key .. " to " .. value

	-- save data to in-memory table
	-- data not in the TX col will be persisted at the end of the phase
	storage[col][key]         = value
	storage[col]["__altered"] = true

	-- track which keys to write to redis
	if (waf._storage_backend == 'redis') then
		waf._storage_redis_setkey[key] = value
		waf._storage_redis_setkey_t    = true
	end
end

function _M.expire_var(waf, ctx, element, value)
	local col     = ctx.col_lookup[string_upper(element.col)]
	local key     = element.key
	local storage = ctx.storage
	local expire  = ngx.now() + value

	--_LOG_"Expiring " .. element.col .. ":" .. element.key .. " in " .. value


	storage[col]["__expire_" .. key] = expire
	storage[col]["__altered"]        = true

	-- track which keys to write to redis
	if (waf._storage_backend == 'redis') then
		waf._storage_redis_setkey['__expire_' .. key] = expire
		--_LOG_cjson.encode(waf._storage_redis_setkey)
	end
end

function _M.delete_var(waf, ctx, element)
	local col     = ctx.col_lookup[string_upper(element.col)]
	local key     = element.key
	local storage = ctx.storage

	--_LOG_"Deleting " .. col .. ":" .. key

	if (storage[col][key]) then
		storage[col][key]         = nil
		storage[col]["__altered"] = true

		-- redis cant expire specific keys in a hash so we track them for hdel when persisting
		if (waf._storage_backend == 'redis') then
			waf._storage_redis_delkey_n = waf._storage_redis_delkey_n + 1
			waf._storage_redis_delkey[waf._storage_redis_delkey_n] = key
		end
	else
		--_LOG_key .. " was not found in " .. col
	end
end

function _M.persist(waf, storage)
	local backend   = waf._storage_backend
	if (not util.table_has_key(backend, _valid_backends)) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	local backend_m = require("resty.waf.storage." .. backend)

	if (not util.table_has_key(backend, _valid_backends)) then
		logger.fatal_fail(backend .. " is not a valid persistent storage backend")
	end

	--_LOG_'Persisting storage type ' .. backend

	for col in pairs(storage) do
		if (col ~= 'TX') then
			--_LOG_'Examining ' .. col

			if (storage[col]["__altered"]) then
				storage[col]["__altered"] = nil -- dont need to persist this flag
				backend_m.persist(waf, col, storage[col])
			else
				--_LOG_"Not persisting a collection that wasn't altered"
			end
		end
	end
end

_M.col_prefix = 'lua_resty_waf_'

return _M
