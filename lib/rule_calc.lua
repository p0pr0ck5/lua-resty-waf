local _M = {}

_M.version = "0.6.0"

local function _transform_collection_key(transform)
	if (not transform) then
		return nil
	end

	if (type(transform) ~= 'table') then
		return tostring(transform)
	else
		return table.concat(transform, ',')
	end
end

local function _build_collection_key(var, transform)
	local key = {}
	key[1] = tostring(var.type)

	if (var.parse ~= nil) then
		local k, v = next(var.parse)

		key[2] = tostring(k)
		key[3] = tostring(v)
		key[4] = tostring(_transform_collection_key(transform))
		key[5] = tostring(var.length)
	else
		key[2] = tostring(_transform_collection_key(transform))
		key[3] = tostring(var.length)
	end

	return table.concat(key, "|")
end

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
		local rule = ruleset[i]

		if (not rule.opts) then rule.opts = {} end

		chain[#chain + 1] = rule

		for i in ipairs(rule.vars) do
			local var = rule.vars[i]
			var.collection_key = _build_collection_key(var, rule.opts.transform)
		end

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
