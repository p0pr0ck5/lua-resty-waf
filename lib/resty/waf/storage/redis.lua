local _M = {}

local base    = require "resty.waf.base"
local cjson   = require "cjson"
local logger  = require "resty.waf.log"
local redis_m = require "resty.redis"
local storage = require "resty.waf.storage"

_M.version = base.version

_M.col_prefix = storage.col_prefix

function _M.initialize(waf, storage, col)
	local redis = redis_m:new()
	local host      = waf._storage_redis_host
	local port      = waf._storage_redis_port

	local ok, err = redis:connect(host, port)
	if not ok then
		logger.warn(waf, "Error in connecting to redis: " .. err)
		storage[col] = {}
		return
	end

	local col_name = _M.col_prefix .. col

	local array, err = redis:hgetall(col_name)
	if err then
		logger.warn(waf, "Error retrieving " .. col .. ": " .. err)
		storage[col] = {}
		return
	end

	if waf._storage_keepalive then
		local timeout = waf._storage_keepalive_timeout
		local size    = waf._storage_keepalive_pool_size

		local ok, err = redis:set_keepalive(timeout, size)
		if not ok then
			logger.warn(waf, "Error setting redis keepalive: " .. err)
		end
	else
		local ok, err = redis:close()
		if not ok then
			logger.warn(waf, "Error closing redis socket: " .. err)
		end
	end

	local altered = false

	if #array == 0 then
		--_LOG_"Initializing an empty collection for " .. col
		storage[col] = {}
	else
		local data = redis:array_to_hash(array)

		-- individual redis hash keys cannot be expired, so we remove
		-- the expired key from the in-memory collection table, and mark
		-- the key for deletion via hdel when we persist
		for key in pairs(data) do
			if not key:find("__", 1, true) and data["__expire_" .. key] then
				--_LOG_"checking " .. key
				if tonumber(data["__expire_" .. key]) < ngx.now() then
					-- do the actual removal
					--_LOG_"Removing expired key: " .. key
					data["__expire_" .. key] = nil
					data[key] = nil

					-- mark this key to get blown away when we persist
					waf._storage_redis_delkey_n = waf._storage_redis_delkey_n + 1
					waf._storage_redis_delkey[waf._storage_redis_delkey_n] = key
					waf._storage_redis_delkey_n = waf._storage_redis_delkey_n + 1
					waf._storage_redis_delkey[waf._storage_redis_delkey_n] = '__expire_' .. key

					altered = true
				end
			end

			-- bah redis and integers :|
			if(data[key] and ngx.re.find(data[key], [=[^\d+$]=], 'oj')) then
				data[key] = tonumber(data[key])
			end
		end

		storage[col] = data
	end

	storage[col]["__altered"] = altered
end

function _M.persist(waf, col, data)
	local serialized = cjson.encode(data)
	--_LOG_'Persisting value: ' .. tostring(serialized)

	local redis = redis_m:new()
	local host  = waf._storage_redis_host
	local port  = waf._storage_redis_port

	local ok, err = redis:connect(host, port)
	if not ok then
		logger.warn(waf, "Error in connecting to redis: " .. err)
		return
	end

	redis:init_pipeline()
	--_LOG_"Redis start pipeline"

	local col_name = _M.col_prefix .. col

	-- build the hdel command to drop expired/deleted keys
	if waf._storage_redis_delkey_n > 0 then
		--_LOG_"Redis hdel"
		for i=1, waf._storage_redis_delkey_n do
			local k = waf._storage_redis_delkey[i]
			redis:hdel(col_name, k)
		end
	end

	-- build the hmset command to save affected keys
	if waf._storage_redis_setkey_t then
		--_LOG_"Redis hmset"
		redis:hmset(col_name, waf._storage_redis_setkey)
	end

	-- do it
	local ok, err = redis:commit_pipeline()
	if not ok then
		logger.warn(waf, "Error in redis pipelining: " .. err)
	end

	if waf._storage_keepalive then
		local timeout = waf._storage_keepalive_timeout
		local size    = waf._storage_keepalive_pool_size

		local ok, err = redis:set_keepalive(timeout, size)
		if not ok then
			logger.warn(waf, "Error setting redis keepalive: " .. err)
		end
	else
		local ok, err = redis:close()
		if not ok then
			logger.warn(waf, "Error closing redis socket: " .. err)
		end
	end
end


return _M
