local _M = {}

_M.version = "0.5.2"

local cjson         = require("cjson")
local file_logger   = require("inc.resty.logger.file")
local socket_logger = require("inc.resty.logger.socket")

local logger    = require("lib.log")
local operators = require("lib.operators")
local storage   = require("lib.storage")
local util      = require("lib.util")

_M.alter_actions = { ACCEPT = true, DENY = true }

_M.parse_collection = {
	specific = function(FW, collection, value)
		logger.log(FW, "_parse_collection is getting a specific value: " .. value)
		return collection[value]
	end,
	ignore = function(FW, collection, value)
		logger.log(FW, "_parse_collection is ignoring a value: " .. value)
		local _collection = {}
		_collection = util.table_copy(collection)
		_collection[value] = nil
		return _collection
	end,
	keys = function(FW, collection)
		logger.log(FW, "_parse_collection is getting the keys")
		return util.table_keys(collection)
	end,
	values = function(FW, collection)
		logger.log(FW, "_parse_collection is getting the values")
		return util.table_values(collection)
	end,
	all = function(FW, collection)
		local n = 0
		local _collection = {}
		for _, key in ipairs(util.table_keys(collection)) do
			n = n + 1
			_collection[n] = key
		end
		for _, value in ipairs(util.table_values(collection)) do
			n = n + 1
			_collection[n] = value
		end
		return _collection
	end
}

_M.actions = {
	LOG = function(FW)
		logger.log(FW, "rule.action was LOG, since we already called log_event this is relatively meaningless")
	end,
	ACCEPT = function(FW, ctx)
		logger.log(FW, "An explicit ACCEPT was sent, so ending this phase with ngx.OK")
		if (FW._mode == "ACTIVE") then
			ngx.exit(ngx.OK)
		end
	end,
	CHAIN = function(FW, ctx)
		logger.log(FW, "Chaining (pre-processed)")
	end,
	SKIP = function(FW, ctx)
		logger.log(FW, "Skipping (pre-processed)")
	end,
	SCORE = function(FW, ctx)
		local new_score = ctx.score + ctx.rule_score
		logger.log(FW, "New score is " .. new_score)
		ctx.score = new_score
	end,
	DENY = function(FW, ctx)
		logger.log(FW, "rule.action was DENY, so telling nginx to quit (from the lib!)")
		if (FW._mode == "ACTIVE") then
			ngx.exit(ngx.HTTP_FORBIDDEN)
		end
	end,
	IGNORE = function(FW)
		logger.log(FW, "Ingoring rule for now")
	end,
	SETVAR = function(FW, ctx, collections)
		storage.set_var(FW, ctx, collections)
	end
}

_M.transform = {
	base64_decode = function(FW, value)
		logger.log(FW, "Decoding from base64: " .. tostring(value))
		local t_val = ngx.decode_base64(tostring(value))
		if (t_val) then
			logger.log(FW, "decode successful, decoded value is " .. t_val)
			return t_val
		else
			logger.log(FW, "decode unsuccessful, returning original value " .. value)
			return value
		end
	end,
	base64_encode = function(FW, value)
		logger.log(FW, "Encoding to base64: " .. tostring(value))
		local t_val = ngx.encode_base64(value)
		logger.log(FW, "encoded value is " .. t_val)
		return t_val
	end,
	compress_whitespace = function(FW, value)
		return ngx.re.gsub(value, [=[\s+]=], ' ', FW._pcre_flags)
	end,
	html_decode = function(FW, value)
		local str = ngx.re.gsub(value, [=[&lt;]=], '<', FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&gt;]=], '>', FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&quot;]=], '"', FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&apos;]=], "'", FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&#(\d+);]=], function(n) return string.char(n[1]) end, FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&#x(\d+);]=], function(n) return string.char(tonumber(n[1],16)) end, FW._pcre_flags)
		str = ngx.re.gsub(str, [=[&amp;]=], '&', FW._pcre_flags)
		logger.log(FW, "html decoded value is " .. str)
		return str
	end,
	lowercase = function(FW, value)
		return string.lower(tostring(value))
	end,
	remove_comments = function(FW, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], '', FW._pcre_flags)
	end,
	remove_whitespace = function(FW, value)
		return ngx.re.gsub(value, [=[\s+]=], '', FW._pcre_flags)
	end,
	replace_comments = function(FW, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', FW._pcre_flags)
	end,
	uri_decode = function(FW, value)
		return ngx.unescape_uri(value)
	end,
}

_M.write_log_events = {
	error = function(FW, t)
		ngx.log(FW._event_log_level, cjson.encode(t))
	end,
	file = function(FW, t)
		if (not file_logger.initted()) then
			file_logger.init{
				path = FW._event_log_target_path,
				flush_limit = FW._event_log_buffer_size,
				periodic_flush = FW._event_log_periodic_flush
			}
		end

		file_logger.log(cjson.encode(t) .. "\n")
	end,
	socket = function(FW, t)
		if (not socket_logger.initted()) then
			socket_logger.init{
				host = FW._event_log_target_host,
				port = FW._event_log_target_port,
				flush_limit = FW._event_log_buffer_size,
				period_flush = FW._event_log_periodic_flush
			}
		end

		socket_logger.log(cjson.encode(t) .. "\n")
	end
}

_M.operators = {
	REGEX       = function(FW, subject, pattern, opts) return operators.regex_match(FW, subject, pattern, opts) end,
	NOT_REGEX   = function(FW, subject, pattern, opts) return not operators.regex_match(FW, subject, pattern, opts) end,
	EQUALS      = function(FW, a, b) return operators.equals(FW, a, b) end,
	NOT_EQUALS  = function(FW, a, b) return not operators.equals(FW, a, b) end,
	GREATER     = function(FW, a, b) return operators.greater(FW, a, b) end,
	NOT_GREATER = function(FW, a, b) return not operators.greater(FW, a, b) end,
	EXISTS      = function(FW, haystack, needle) return util.table_has_value(FW, needle, haystack) end,
	NOT_EXISTS  = function(FW, haystack, needle) return not util.table_has_value(FW, needle, haystack) end,
	PM          = function(FW, needle, haystack, ctx) return operators.ac_lookup(FW, needle, haystack, ctx) end,
	NOT_PM      = function(FW, needle, haystack, ctx) return not operators.ac_lookup(FW, needle, haystack, ctx) end
}


_M.set_option = {
	whitelist = function(FW, value)
		local t = FW._whitelist
		FW._whitelist[#t + 1] = value
	end,
	blacklist = function(FW, value)
		local t = FW._blacklist
		FW._blacklist[#t + 1] = value
	end,
	ignore_ruleset = function(FW, value)
		local t = {}
		local n = 1
		for k, v in ipairs(FW._active_rulesets) do
			if (v ~= value) then
				t[n] = v
				n = n + 1
			end
		end
		FW._active_rulesets = t
	end,
	ignore_rule = function(FW, value)
		FW._ignored_rules[value] = true
	end,
	disable_pcre_optimization = function(FW, value)
		if (value == true) then
			FW._pcre_flags = 'i'
		end
	end,
	storage_zone = function(FW, value)
		if (not ngx.shared[value]) then
			logger.fatal_fail("Attempted to set FreeWAF storage zone as " .. tostring(value) .. ", but that lua_shared_dict does not exist")
		end
		FW._storage_zone = value
	end,
	allowed_content_types = function(FW, value)
		local t = FW._allowed_content_types
		FW._allowed_content_types[#t + 1] = value
	end,
}

return _M
