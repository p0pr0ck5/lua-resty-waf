local _M = {}

_M.version = "0.5.2"

-- debug logger
function _M.log(FW, msg)
	if (FW._debug == true) then
		ngx.log(FW._debug_log_level, msg)
	end
end

-- fatal failure logger
function _M.fatal_fail(msg)
	ngx.log(ngx.ERR, error(msg))
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

return _M
