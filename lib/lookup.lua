local _M = {}

_M.version = "0.7.1"

local cjson         = require("cjson")
local file_logger   = require("inc.resty.logger.file")
local socket_logger = require("inc.resty.logger.socket")

local logger    = require("lib.log")
local operators = require("lib.operators")
local request   = require("lib.request")
local storage   = require("lib.storage")
local util      = require("lib.util")

_M.alter_actions = { ACCEPT = true, DENY = true }

_M.collections = {
	access = function(waf, collections, ctx)
		local request_headers     = ngx.req.get_headers()
		local request_uri_args    = ngx.req.get_uri_args()
		local request_uri         = request.request_uri()
		local request_basename    = request.basename(waf, ngx.var.uri)
		local request_body        = request.parse_request_body(waf, request_headers)
		local request_cookies     = request.cookies() or {}
		local request_common_args = request.common_args(waf, { request_uri_args, request_body, request_cookies })

		collections.REMOTE_ADDR       = ngx.var.remote_addr
		collections.HTTP_VERSION      = ngx.req.http_version()
		collections.METHOD            = ngx.req.get_method()
		collections.URI               = ngx.var.uri
		collections.URI_ARGS          = request_uri_args
		collections.QUERY_STRING      = ngx.var.query_string
		collections.REQUEST_URI       = request_uri
		collections.REQUEST_BASENAME  = request_basename
		collections.REQUEST_HEADERS   = request_headers
		collections.COOKIES           = request_cookies
		collections.REQUEST_BODY      = request_body
		collections.REQUEST_ARGS      = request_common_args
		collections.REQUEST_LINE      = ngx.var.request
		collections.PROTOCOL          = ngx.var.server_protocol
		collections.TX                = ctx.storage["TX"]
		collections.NGX_VAR           = ngx.var
		collections.MATCHED_VARS      = {}
		collections.MATCHED_VAR_NAMES = {}
		collections.SCORE             = function() return ctx.score end
		collections.SCORE_THRESHOLD   = function(waf) return waf._score_threshold end
	end,
	header_filter = function(waf, collections)
		local response_headers = ngx.resp.get_headers()

		collections.RESPONSE_HEADERS = response_headers
		collections.STATUS           = ngx.status
	end,
	body_filter = function(waf, collections, ctx)
		if ctx.buffers == nil then
			ctx.buffers  = {}
			ctx.nbuffers = 0
		end

		local data  = ngx.arg[1]
		local eof   = ngx.arg[2]
		local index = ctx.nbuffers + 1

		local res_length = tonumber(collections.RESPONSE_HEADERS["content-length"])
		local res_type   = collections.RESPONSE_HEADERS["content-type"]

		if (not res_length or res_length > waf._res_body_max_size) then
			ctx.short_circuit = not eof
			return
		end

		if (not res_type or not util.table_has_key(res_type, waf._res_body_mime_types)) then
			ctx.short_circuit = not eof
			return
		end

		if data then
			ctx.buffers[index] = data
			ctx.nbuffers = index
		end

		if not eof then
			-- Send nothing to the client yet.
			ngx.arg[1] = nil

			-- no need to process further at this point
			ctx.short_circuit = true
			return
		else
			collections.RESPONSE_BODY = table.concat(ctx.buffers, '')
			ngx.arg[1] = collections.RESPONSE_BODY
		end
	end
}

_M.parse_collection = {
	specific = function(waf, collection, value)
		logger.log(waf, "Parse collection is getting a specific value: " .. value)
		return collection[value]
	end,
	ignore = function(waf, collection, value)
		logger.log(waf, "Parse collection is ignoring a value: " .. value)
		local _collection = {}
		_collection = util.table_copy(collection)
		_collection[value] = nil
		return _collection
	end,
	keys = function(waf, collection)
		logger.log(waf, "Parse collection is getting the keys")
		return util.table_keys(collection)
	end,
	values = function(waf, collection)
		logger.log(waf, "Parse collection is getting the values")
		return util.table_values(collection)
	end,
	all = function(waf, collection)
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
	ACCEPT = function(waf, ctx)
		logger.log(waf, "Rule action was ACCEPT, so ending this phase with ngx.OK")
		if (waf._mode == "ACTIVE") then
			ngx.exit(ngx.OK)
		end
	end,
	CHAIN = function(waf, ctx)
		logger.log(waf, "Chaining (pre-processed)")
	end,
	SCORE = function(waf, ctx)
		local new_score = ctx.score + ctx.rule_score
		logger.log(waf, "New score is " .. new_score)
		ctx.score = new_score
	end,
	DENY = function(waf, ctx)
		logger.log(waf, "Rule action was DENY, so telling nginx to quit (from the lib!)")
		if (waf._mode == "ACTIVE") then
			ngx.exit(waf._deny_status)
		end
	end,
	IGNORE = function(waf)
		logger.log(waf, "Ignoring rule for now")
	end,
}

_M.transform = {
	base64_decode = function(waf, value)
		logger.log(waf, "Decoding from base64: " .. tostring(value))
		local t_val = ngx.decode_base64(tostring(value))
		if (t_val) then
			logger.log(waf, "Decode successful, decoded value is " .. t_val)
			return t_val
		else
			logger.log(waf, "Decode unsuccessful, returning original value " .. value)
			return value
		end
	end,
	base64_encode = function(waf, value)
		logger.log(waf, "Encoding to base64: " .. tostring(value))
		local t_val = ngx.encode_base64(value)
		logger.log(waf, "Encoded value is " .. t_val)
		return t_val
	end,
	compress_whitespace = function(waf, value)
		return ngx.re.gsub(value, [=[\s+]=], ' ', waf._pcre_flags)
	end,
	hex_decode = function(waf, value)
		return util.hex_decode(value)
	end,
	hex_encode = function(waf, value)
		return util.hex_encode(value)
	end,
	html_decode = function(waf, value)
		local str = ngx.re.gsub(value, [=[&lt;]=], '<', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&gt;]=], '>', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&quot;]=], '"', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&apos;]=], "'", waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&#(\d+);]=], function(n) return string.char(n[1]) end, waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&#x(\d+);]=], function(n) return string.char(tonumber(n[1],16)) end, waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&amp;]=], '&', waf._pcre_flags)
		logger.log(waf, "html decoded value is " .. str)
		return str
	end,
	length = function(waf, value)
		return string.len(tostring(value))
	end,
	lowercase = function(waf, value)
		return string.lower(tostring(value))
	end,
	md5 = function(waf, value)
		return ngx.md5_bin(value)
	end,
	normalise_path = function(waf, value)
		while (ngx.re.match(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], waf._pcre_flags)) do
			value = ngx.re.gsub(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], '/', waf._pcre_flags)
		end
		return value
	end,
	remove_comments = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], '', waf._pcre_flags)
	end,
	remove_comments_char = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*|\*\/|--|#]=], '', waf._pcre_flags)
	end,
	remove_whitespace = function(waf, value)
		return ngx.re.gsub(value, [=[\s+]=], '', waf._pcre_flags)
	end,
	replace_comments = function(waf, value)
		return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', waf._pcre_flags)
	end,
	sha1 = function(waf, value)
		return ngx.sha1_bin(value)
	end,
	sql_hex_decode = function(waf, value)
		if (string.find(value, '0x', 1, true)) then
			value = string.sub(value, 3)
			return util.hex_decode(value)
		else
			return value
		end
	end,
	trim = function(waf, value)
		return ngx.re.gsub(value, [=[^\s*|\s+$]=], '')
	end,
	trim_left = function(waf, value)
		return ngx.re.sub(value, [=[^\s+]=], '')
	end,
	trim_right = function(waf, value)
		return ngx.re.sub(value, [=[\s+$]=], '')
	end,
	uri_decode = function(waf, value)
		return ngx.unescape_uri(value)
	end,
}

_M.write_log_events = {
	error = function(waf, t)
		ngx.log(waf._event_log_level, cjson.encode(t))
	end,
	file = function(waf, t)
		if (not file_logger.initted()) then
			file_logger.init({
				path           = waf._event_log_target_path,
				flush_limit    = waf._event_log_buffer_size,
				periodic_flush = waf._event_log_periodic_flush
			})
		end

		file_logger.log(cjson.encode(t) .. "\n")
	end,
	socket = function(waf, t)
		if (not socket_logger.initted()) then
			socket_logger.init({
				host           = waf._event_log_target_host,
				port           = waf._event_log_target_port,
				sock_type      = waf._event_log_socket_proto,
				ssl            = waf._event_log_ssl,
				ssl_verify     = waf._event_log_ssl_verify,
				sni_host       = waf._event_log_ssl_sni_host,
				flush_limit    = waf._event_log_buffer_size,
				periodic_flush = waf._event_log_periodic_flush
			})
		end

		socket_logger.log(cjson.encode(t) .. "\n")
	end
}

_M.operators = {
	REGEX        = function(waf, collection, pattern) return operators.regex(waf, collection, pattern) end,
	EQUALS       = function(waf, collection, pattern) return operators.equals(collection, pattern) end,
	GREATER      = function(waf, collection, pattern) return operators.greater(collection, pattern) end,
	LESS         = function(waf, collection, pattern) return operators.less(collection, pattern) end,
	GREATER_EQ   = function(waf, collection, pattern) return operators.greater_equals(collection, pattern) end,
	LESS_EQ      = function(waf, collection, pattern) return operators.less_equals(collection, pattern) end,
	EXISTS       = function(waf, collection, pattern) return operators.exists(collection, pattern) end,
	CONTAINS     = function(waf, collection, pattern) return operators.contains(collection, pattern) end,
	STR_EXISTS   = function(waf, collection, pattern) return operators.str_find(waf, pattern, collection) end,
	STR_CONTAINS = function(waf, collection, pattern) return operators.str_find(waf, collection, pattern) end,
	PM           = function(waf, collection, pattern, ctx) return operators.ac_lookup(collection, pattern, ctx) end,
	CIDR_MATCH   = function(waf, collection, pattern) return operators.cidr_match(collection, pattern) end,
	RBL_LOOKUP   = function(waf, collection, pattern, ctx) return operators.rbl_lookup(collection, pattern, ctx) end,
	DETECT_SQLI  = function(waf, collection, pattern) return operators.detect_sqli(collection) end,
	DETECT_XSS   = function(waf, collection, pattern) return operators.detect_xss(collection) end,
}

_M.set_option = {
	ignore_ruleset = function(waf, value)
		waf._ignore_ruleset[#waf._ignore_ruleset + 1] = value
		waf.need_merge = true
	end,
	add_ruleset = function(waf, value)
		waf._add_ruleset[#waf._add_ruleset + 1] = value
		waf.need_merge = true
	end,
	ignore_rule = function(waf, value)
		waf._ignore_rule[value] = true
	end,
	disable_pcre_optimization = function(waf, value)
		if (value == true) then
			waf._pcre_flags = 'i'
		end
	end,
	storage_zone = function(waf, value)
		if (not ngx.shared[value]) then
			logger.fatal_fail("Attempted to set lua-resty-waf storage zone as " .. tostring(value) .. ", but that lua_shared_dict does not exist")
		end
		waf._storage_zone = value
	end,
	allowed_content_types = function(waf, value)
		waf._allowed_content_types[value] = true
	end,
	res_body_mime_types = function(waf, value)
		waf._res_body_mime_types[value] = true
	end,
	event_log_ngx_vars = function(waf, value)
		waf._event_log_ngx_vars[value] = true
	end,
	nameservers = function(waf, value)
		waf._nameservers[#waf._nameservers + 1] = value
	end
}

return _M
