local _M = {}

_M.version = "0.5.2"

local util = require "lib.util"

_M.phases = { access = 1, header_filter = 2, body_filter = 3 }

function _M.is_valid_phase(FW, phase)
	return util.table_has_key(FW, phase, _M.phases)
end

return _M
