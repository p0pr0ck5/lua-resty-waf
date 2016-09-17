local _M = {}

_M.version = "0.8.2"

local cjson       = require "cjson"
local logger      = require "resty.waf.log"
local memcached_m = require "resty.memcached"

function _M.initialize(waf, storage, col)
	local memcached = memcached_m:new()
	local host      = waf._storage_memcached_host
	local port      = waf._storage_memcached_port

	local ok, err = memcached:connect(host, port)
	if (not ok) then
		logger.warn(waf, "Error in connecting to memcached: " .. err)
		storage[col] = {}
		return
	end

	local serialized, flags, err = memcached:get(col)
	if (err) then
		logger.warn(waf, "Error retrieving " .. col .. ": " .. err)
		storage[col] = {}
		return
	end

	if (waf._storage_keepalive) then
		local timeout = waf._storage_keepalive_timeout
		local size    = waf._storage_keepalive_pool_size

		local ok, err = memcached:set_keepalive(timeout, size)
		if (not ok) then
			logger.warn(waf, "Error setting memcached keepalive: " .. err)
		end
	else
		local ok, err = memcached:close()
		if (not ok) then
			logger.warn("Error closing memcached socket: " .. err)
		end
	end

	local altered = false

	if (not serialized) then
		logger.warn(waf, "Initializing an empty collection for " .. col)
		storage[col] = {}
	else
		local data = cjson.decode(serialized)

		-- because we're serializing out the contents of the collection
		-- we need to roll our own expire handling
		for key in pairs(data) do
			if (not key:find("__", 1, true) and data["__expire_" .. key]) then
				logger.log(waf, "checking " .. key)
				if (data["__expire_" .. key] < ngx.now()) then
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

function _M.persist(waf, col, data)
	local serialized = cjson.encode(data)
	logger.log(waf, 'Persisting value: ' .. tostring(serialized))

	local memcached = memcached_m:new()
	local host      = waf._storage_memcached_host
	local port      = waf._storage_memcached_port

	local ok, err = memcached:connect(host, port)
	if (not ok) then
		logger.warn(waf, "Error in connecting to memcached: " .. err)
		return
	end

	local ok, err = memcached:set(col, serialized)
	if (not ok) then
		logger.warn(waf, "Error persisting storage data: " .. err)
	end

	if (waf._storage_keepalive) then
		local timeout = waf._storage_keepalive_timeout
		local size    = waf._storage_keepalive_pool_size

		local ok, err = memcached:set_keepalive(timeout, size)
		if (not ok) then
			logger.warn(waf, "Error setting memcached keepalive: " .. err)
		end
	else
		local ok, err = memcached:close()
		if (not ok) then
			logger.warn("Error closing memcached socket: " .. err)
		end
	end
end


return _M
