local _M = {}

local base = require "resty.waf.base"
local util = require "resty.waf.util"

_M.version = base.version

_M.phases = { access = 1, header_filter = 2, body_filter = 3, log = 4 }

function _M.is_valid_phase(phase)
	return util.table_has_key(phase, _M.phases)
end

return _M
