local _M = {}

_M.version = "0.5.2"

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

		setmetatable(copy, _M.table_copy(FW, getmetatable(orig)))
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
function _M.table_has_key(FW, needle, haystack)
	if (type(haystack) ~= "table") then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	logger.log(FW, "table key " .. needle .. " is " .. tostring(haystack[needle]))

	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
function _M.table_has_value(FW, needle, haystack)
	logger.log(FW, "Searching for " .. needle)

	if (type(haystack) ~= "table") then
		logger.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		logger.log(FW, "Checking " .. value)

		if (value == needle) then
			return true
		end
	end

	return false
end

-- pick out dynamic data from storage key definitions
function _M.parse_dynamic_value(FW, key, collections)
	local lookup = function(m)
		local val = collections[m[1]]

		if (not val) then
			logger.fatal_fail("Bad dynamic parse, no collection key " .. m[1])
		end

		if (type(val) == "table") then
			return m[1]
		elseif (type(val) == "function") then
			return val(FW)
		else
			return val
		end
	end

	-- use a negated character (instead of a lazy regex) to grab something that looks like
	-- %{VAL}
	-- and find it in the lookup table
	local str = ngx.re.gsub(key, [=[%{([^{]*)}]=], lookup, FW._pcre_flags)

	logger.log(FW, "parsed dynamic value is " .. str)

	if (ngx.re.find(str, [=[^\d+$]=], FW._pcre_flags)) then
		return tonumber(str)
	else
		return str
	end
end

return _M
