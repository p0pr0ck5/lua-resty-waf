local _M = {}

local base   = require "resty.waf.base"
local random = require "resty.random"
local string = require "resty.string"

_M.version = base.version

function _M.random_bytes(len)
	return string.to_hex(random.bytes(len))
end

return _M
