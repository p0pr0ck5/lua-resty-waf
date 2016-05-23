local _M = {}

_M.version = "0.7.2"

local cjson  = require("cjson")
local logger = require("lib.log")

-- duplicate a table using recursion if necessary for multi-dimensional tables
-- useful for getting a local copy of a table
function _M.table_copy(orig)
	local orig_type = type(orig)
	local copy

	if (orig_type == 'table') then
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
	if (type(table) ~= "table") then
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
	if (type(table) ~= "table") then
		logger.fatal_fail(type(table) .. " was given to table_values!")
	end

	local t = {}
	local n = 0

	for _, value in pairs(table) do
		-- if a table as a table of values, we need to break them out and add them individually
		-- request_url_args is an example of this, e.g. ?foo=bar&foo=bar2
		if (type(value) == "table") then
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
	if (type(haystack) ~= "table") then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
function _M.table_has_value(needle, haystack)
	if (type(haystack) ~= "table") then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		if (value == needle) then
			return true
		end
	end

	return false
end

-- pick out dynamic data from storage key definitions
function _M.parse_dynamic_value(waf, key, collections)
	local lookup = function(m)
		local val      = collections[string.upper(m[1])]
		local specific = m[2]

		if (not val) then
			logger.fatal_fail("Bad dynamic parse, no collection key " .. m[1])
		end

		if (type(val) == "table") then
			if (specific) then
				return tostring(val[specific])
			else
				return m[1]
			end
		elseif (type(val) == "function") then
			return val(waf)
		else
			return val
		end
	end

	-- grab something that looks like
	-- %{VAL} or %{VAL.foo}
	-- and find it in the lookup table
	local str = ngx.re.gsub(key, [[%{([A-Za-z_]+)(?:\.([^}]+))?}]], lookup, waf._pcre_flags)

	logger.log(waf, "Parsed dynamic value is " .. str)

	if (ngx.re.find(str, [=[^\d+$]=], waf._pcre_flags)) then
		return tonumber(str)
	else
		return str
	end
end

-- find a rule file with a .json prefix, read it, and return a ruleset table
function _M.load_ruleset(name)
	for k, v in string.gmatch(package.path, "[^;]+") do
		local path = string.match(k, "(.*/)")

		local full_name = path .. "rules/" .. name .. ".json"

		local f = io.open(full_name)
		if (f ~= nil) then
			local data  = f:read("*all")
			local jdata

			if pcall(function() jdata = cjson.decode(data) end) then
				return jdata, nil
			else
				return nil, "could not decode " .. data
			end
		end
	end

	return nil, "could not find " .. name
end

-- encode a given string as hex
function _M.hex_encode(str)
	return (str:gsub('.', function (c)
		return string.format('%02x', string.byte(c))
	end))
end

-- decode a given hex string
function _M.hex_decode(str)
	local value

	if (pcall(function()
		value = str:gsub('..', function (cc)
			return string.char(tonumber(cc, 16))
		end)
	end)) then
		return value
	else
		return str
	end
end

-- build an RBLDNS query by reversing the octets of an IPv4 address and prepending that to the rbl server name
function _M.build_rbl_query(ip, rbl_srv)
	if (type(ip) ~= 'string') then
		return false
	end

	local o1, o2, o3, o4 = ip:match("(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)")

	if (not o1 and not o2 and not o3 and not o4) then
		return false
	end

	local t = { o4, o3, o2, o1, rbl_srv }

	return table.concat(t, '.')
end

return _M
