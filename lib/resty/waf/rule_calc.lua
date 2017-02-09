local _M = {}

local table_concat = table.concat
local table_insert = table.insert

_M.version = "0.9"

local function _transform_collection_key(transform)
	if (not transform) then
		return nil
	end

	if (type(transform) ~= 'table') then
		return tostring(transform)
	else
		return table_concat(transform, ',')
	end
end

local function _ignore_collection_key(ignore)
	local t = {}

	for i, j in ipairs(ignore) do
		table_insert(t, table_concat(j, ','))
	end

	return table_concat(t, ',')
end

local function _build_collection_key(var, transform)
	local key = {}
	key[1] = tostring(var.type)

	if (var.parse ~= nil) then
		table_insert(key, var.parse[1])
		table_insert(key, var.parse[2])
	end

	if (var.ignore ~= nil) then
		table_insert(key, tostring(_ignore_collection_key(var.ignore)))
	end

	table_insert(key, tostring(_transform_collection_key(transform)))

	return table_concat(key, "|")
end

local function _write_chain_offsets(chain, max, cur_offset)
	local chain_length = #chain
	local offset = chain_length

	for i = 1, chain_length do
		local rule = chain[i]

		if (offset + cur_offset >= max) then
			rule.offset_nomatch = nil
			if (rule.actions.disrupt == "CHAIN") then
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
	local offset = rule.skip + 1

	rule.offset_nomatch = 1

	if (offset + cur_offset > max) then
		rule.offset_match = nil
	else
		rule.offset_match = offset
	end
end

function _M.calculate(ruleset, meta_lookup)
	local max = #ruleset
	local chain = {}

	for i = 1, max do
		local rule = ruleset[i]

		if (not rule.opts) then rule.opts = {} end

		chain[#chain + 1] = rule

		for i in ipairs(rule.vars) do
			local var = rule.vars[i]
			var.collection_key = _build_collection_key(var, rule.opts.transform)
		end

		if (rule.actions.disrupt ~= "CHAIN") then
			_write_chain_offsets(chain, max, i - #chain)

			if (rule.skip) then
				_write_skip_offset(rule, max, i)
			elseif (rule.skip_after) then
				local skip_after = rule.skip_after
				-- read ahead in the chain to look for our target
				-- when we find it, set the rule's skip value appropriately
				local j, ctr
				ctr = 0
				for j = i, max do
					ctr = ctr + 1
					local check_rule = ruleset[j]
					if (check_rule.id == skip_after) then
						break
					end
				end

				rule.skip = ctr - 1
				_write_skip_offset(rule, max, i)
			end

			chain = {}
		end

		-- meta table lookups for exceptions
		if (meta_lookup) then
			if (rule.msg) then
				local msg = rule.msg

				if (not meta_lookup.msgs[msg]) then
					meta_lookup.msgs[msg] = { rule.id }
				else
					table_insert(meta_lookup.msgs[msg], rule.id)
				end
			end

			if (rule.tag) then
				for _, tag in ipairs(rule.tag) do
					if (not meta_lookup.tags[tag]) then
						meta_lookup.tags[tag] = { rule.id }
					else
						table_insert(meta_lookup.tags[tag], rule.id)
					end
				end
			end
		end
	end
end

return _M
