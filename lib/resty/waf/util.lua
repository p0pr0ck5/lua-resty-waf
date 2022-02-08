local _M = {}

local base   = require "resty.waf.base"
local cjson  = require "cjson"
local logger = require "resty.waf.log"
-- util must be imported from https://github.com/mozilla-services/lua_sandbox_extensions/blob/main/heka/modules/heka/util.lua
local util = require("util")

local re_find       = ngx.re.find
local string_byte   = string.byte
local string_char   = string.char
local string_find   = string.find
local string_format = string.format
local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local string_match  = string.match
local string_sub    = string.sub
local string_upper  = string.upper
local table_concat  = table.concat

_M.version = base.version

-- duplicate a table using recursion if necessary for multi-dimensional tables
-- useful for getting a local copy of a table
function _M.table_copy(orig)
	local orig_type = type(orig)
	local copy

	if orig_type == 'table' then
		copy = {}

		for orig_key, orig_value in next, orig, nil do
			copy[_M.table_copy(orig_key)] = _M.table_copy(orig_value)
		end

		setmetatable(copy, _M.table_copy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

-- return a table containing the keys of the provided table
function _M.table_keys(table)
	if type(table) ~= "table" then
		logger.fatal_fail(type(table) .. " was given to table_keys!")
	end

	local t = {}
	local n = 0

	for key, _ in pairs(table) do
		n = n + 1
		t[n] = tostring(key)
	end

	return t
end

-- return a table containing the values of the provided table
function _M.table_values(table)
	if type(table) ~= "table" then
		logger.fatal_fail(type(table) .. " was given to table_values!")
	end

	local t = {}
	local n = 0

	for _, value in pairs(table) do
		-- if a table as a table of values, we need to break them out and add them individually
		-- request_url_args is an example of this, e.g. ?foo=bar&foo=bar2
		if type(value) == "table" then
			for _, values in pairs(value) do
				n = n + 1
				t[n] = tostring(values)
			end
		else
			n = n + 1
			t[n] = tostring(value)
		end
	end

	return t
end

-- return true if the table key exists
function _M.table_has_key(needle, haystack)
	if type(haystack) ~= "table" then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
function _M.table_has_value(needle, haystack)
	if type(haystack) ~= "table" then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		if value == needle then
			return true
		end
	end

	return false
end

-- append the contents of (array-like) table b into table a
function _M.table_append(a, b)
	-- handle some ugliness
	local c = type(b) == 'table' and b or { b }

	local a_count = #a

	for i = 1, #c do
		a_count = a_count + 1
		a[a_count] = c[i]
	end
end

-- pick out dynamic data from storage key definitions
function _M.parse_dynamic_value(waf, key, collections)
	local lookup = function(macro)
		local val, specific
		-- cheat on the start index
		local dot = string_find(macro, "%.", 5)
		if dot then
			val = string_sub(macro, 3, dot - 1)
			specific = string_sub(macro, dot + 1, -2)
		else
			val = string_sub(macro, 3, -2)
		end

		local lval = collections[val]

		if type(lval) == "table" then
			if specific then
				return lval[specific] and tostring(lval[specific]) or
					tostring(lval[string.lower(specific)])
			else
				return val
			end
		else
			return lval
		end
	end

	local str = string_gsub(key, "%%%b{}", lookup)

	--_LOG_"Parsed dynamic value is " .. str

	return tonumber(str) and tonumber(str) or str
end

-- safely attempt to parse a JSON string as a ruleset
function _M.parse_ruleset(data)
	local jdata

	if pcall(function() jdata = cjson.decode(data) end) then
		return jdata, nil
	else
		return nil, "could not decode " .. data
	end
end

-- find a rule file with a .json suffix, read it, and return a JSON string
function _M.load_ruleset_file(name)
	for k, v in string_gmatch(package.path, "[^;]+") do
		local path = string_match(k, "(.*/)")

		local full_name = path .. "rules/" .. name .. ".json"

		local f = io.open(full_name)
		if f ~= nil then
			local data = f:read("*all")

			f:close()

			return _M.parse_ruleset(data)
		end
	end

	return nil, "could not find " .. name
end

-- encode a given string as hex
function _M.hex_encode(str)
	return (str:gsub('.', function (c)
		return string_format('%02x', string_byte(c))
	end))
end

-- decode a given hex string
function _M.hex_decode(str)
	local value

	if (pcall(function()
		value = str:gsub('..', function (cc)
			return string_char(tonumber(cc, 16))
		end)
	end)) then
		return value
	else
		return str
	end
end

-- build an RBLDNS query by reversing the octets of an IPv4 address and prepending that to the rbl server name
function _M.build_rbl_query(ip, rbl_srv)
	if type(ip) ~= 'string' then
		return false
	end

	local o1, o2, o3, o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")

	if not o1 and not o2 and not o3 and not o4 then
		return false
	end

	local t = { o4, o3, o2, o1, rbl_srv }

	return table_concat(t, '.')
end

-- parse collection elements based on a given directive
_M.parse_collection = {
	specific = function(waf, collection, value)
		--_LOG_"Parse collection is getting a specific value: " .. value
		return collection[value]
	end,
	regex = function(waf, collection, value)
		--_LOG_"Parse collection is geting the regex: " .. value
		local v
		local n = 0
		local _collection = {}
		for k, _ in pairs(collection) do
			--_LOG_"checking " .. k
			if ngx.re.find(k, value, waf._pcre_flags) then
				v = collection[k]
				if type(v) == "table" then
					for __, _v in pairs(v) do
						n = n + 1
						_collection[n] = _v
					end
				else
					n = n + 1
					_collection[n] = v
				end
			end
		end
		return _collection
	end,
	keys = function(waf, collection)
		--_LOG_"Parse collection is getting the keys"
		return _M.table_keys(collection)
	end,
	values = function(waf, collection)
		--_LOG_"Parse collection is getting the values"
		return _M.table_values(collection)
	end,
	all = function(waf, collection)
		local n = 0
		local _collection = {}
		for _, key in ipairs(_M.table_keys(collection)) do
			n = n + 1
			_collection[n] = key
		end
		for _, value in ipairs(_M.table_values(collection)) do
			n = n + 1
			_collection[n] = value
		end
		return _collection
	end
}

_M.sieve_collection = {
	ignore = function(waf, collection, value)
		--_LOG_"Sieveing specific value " .. value
		collection[value] = nil
	end,
	regex = function(waf, collection, value)
		--_LOG_"Sieveing regex value " .. value
		for k, _ in pairs(collection) do
			--_LOG_"Checking " .. k
			if ngx.re.find(k, value, waf._pcre_flags) then
				--_LOG_"Removing " .. k
				collection[k] = nil
			end
		end
	end,
}

-- build the msg/tag exception table for a given rule
function _M.rule_exception(exception_table, rule)
	if not rule.exceptions then
		return
	end

	local ids   = {}
	local count = 0

	for i, exception in ipairs(rule.exceptions) do
		for key, rules in pairs(exception_table.msgs) do
			if re_find(key, exception, 'jo') then
				for j, id in ipairs(rules) do
					count = count + 1
					ids[count] = id
				end
			end
		end

		for key, rules in pairs(exception_table.tags) do
			if re_find(key, exception, 'jo') then
				for j, id in ipairs(rules) do
					count = count + 1
					ids[count] = id
				end
			end
		end
	end

	if count > 0 then
		exception_table.meta_ids[rule.id] = ids
	end
end

-- function to unpack a nested json array into a single array
function _M.unpack_json(waf, json_object)
    local flat = {}
    util.table_to_fields(json_object, flat, nil, ".", waf._max_json_depth)
    return flat
end

return _M
