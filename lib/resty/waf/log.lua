local _M = {}

local base          = require "resty.waf.base"
local cjson         = require "cjson"
local socket_logger = require "resty.logger.socket"

_M.version = base.version

local function split(source, delimiter)
	local elements = {}
	local pattern = '([^'..delimiter..']+)'
	string.gsub(source, pattern, function(value)
		elements[#elements + 1] = value
	end)
	return elements
end

-- warn logger
function _M.warn(waf, msg)
	ngx.log(ngx.WARN, '[', waf.transaction_id, '] ', msg)
end

-- deprecation logger
function _M.deprecate(waf, msg, ver)
	_M.warn(waf, 'DEPRECATED: ' .. msg)

	if not ver then return end

	local ver_tab = split(ver, "%.")
	local my_ver  = split(base.version, "%.")

	for i = 1, #ver_tab do
		local m = tonumber(ver_tab[i]) or 0
		local n = tonumber(my_ver[i]) or 0

		if n > m then
			_M.fatal_fail("fatal deprecation version passed", 1)
		end
	end
end

-- fatal failure logger
function _M.fatal_fail(msg, level)
	level = tonumber(level) or 0
	ngx.log(ngx.ERR, error(msg, level + 2))
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- event log writer lookup table
_M.write_log_events = {
	error = function(waf, t)
		ngx.log(waf._event_log_level, cjson.encode(t))
	end,
	file = function(waf, t)
		if not waf._event_log_target_path then
			_M.fatal_fail("Event log target path is undefined in file logger")
		end

		local f = io.open(waf._event_log_target_path, 'a')

		if not f then
			_M.warn(waf, "Could not open " .. waf._event_log_target_path)
			return
		end

		f:write(cjson.encode(t), "\n")
		f:close()
	end,
	socket = function(waf, t)
		if not socket_logger.initted() then
			socket_logger.init({
				host           = waf._event_log_target_host,
				port           = waf._event_log_target_port,
				sock_type      = waf._event_log_socket_proto,
				ssl            = waf._event_log_ssl,
				ssl_verify     = waf._event_log_ssl_verify,
				sni_host       = waf._event_log_ssl_sni_host,
				flush_limit    = waf._event_log_buffer_size,
				periodic_flush = waf._event_log_periodic_flush
			})
		end

		socket_logger.log(cjson.encode(t) .. "\n")
	end
}

return _M
