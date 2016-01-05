local _M = {}

_M.version = "0.5.2"

local function _write_chain_offsets(chain, max, cur_offset)
	local chain_length = #chain
	local offset = chain_length

	for i = 1, chain_length do
		local rule = chain[i]

		if (offset + cur_offset >= max) then
			rule.offset_nomatch = nil
			if (rule.action == "CHAIN") then
				rule.offset_match = 1
			else
				rule.offset_match = nil
			end
		else
			rule.offset_nomatch = offset
			rule.offset_match = 1
		end

		cur_offset = cur_offset + 1
		offset = offset - 1
	end
end

local function _write_skip_offset(rule, max, cur_offset)
	local offset = rule.opts.skip + 1

	rule.offset_nomatch = 1

	if (offset + cur_offset > max) then
		rule.offset_match = nil
	else
		rule.offset_match = offset
	end
end

function _M.calculate(ruleset)
	local max = #ruleset
	local chain = {}
	local sentinal = false

	for i = 1, max do
		skip = false
		local rule = ruleset[i]

		chain[#chain + 1] = rule

		if (rule.action == "SKIP") then
			_write_skip_offset(rule, max, i)
			chain = {}
		elseif (rule.action ~= "CHAIN") then
			sentinal = true
		end

		if (sentinal) then
			_write_chain_offsets(chain, max, i - #chain)
			sentinal = false
			chain = {}
		end
	end
end

return _M
