local _M = {}

_M.version = "0.9"

local random = require "resty.random"
local string = require "resty.string"

function _M.random_bytes(len)
	return string.to_hex(random.bytes(len))
end

return _M
