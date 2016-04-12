local _M = {}

_M.version = "0.7.1"

-- debug logger
function _M.log(waf, msg)
	if (waf._debug == true) then
		ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', msg)
	end
end

-- fatal failure logger
function _M.fatal_fail(msg)
	ngx.log(ngx.ERR, error(msg))
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

return _M
