local _M = {}

_M.version = "0.6.0"

local random = require "inc.resty.random"
local string = require "inc.resty.string"

function _M.random_bytes(len)
	return string.to_hex(random.bytes(len))
end

return _M
