local _M = {}

_M.version = "0.8"

local cjson         = require "cjson"
local file_logger   = require "resty.logger.file"
local socket_logger = require "resty.logger.socket"

local actions   = require "resty.waf.actions"
local logger    = require "resty.waf.log"
local operators = require "resty.waf.operators"
local request   = require "resty.waf.request"
local storage   = require "resty.waf.storage"
local util      = require "resty.waf.util"

local string_char   = string.char
local string_find   = string.find
local string_format = string.format
local string_len    = string.len
local string_lower  = string.lower
local string_match  = string.match
local string_sub    = string.sub
local table_concat  = table.concat

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
		collections.SCORE_THRESHOLD   = waf._score_threshold

		local year, month, day, hour, minute, second = string_match(ngx.localtime(),
			"(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)")

		collections.TIME              = string_format("%d:%d:%d", hour, minute, second)
		collections.TIME_DAY          = day
		collections.TIME_EPOCH        = ngx.time()
		collections.TIME_HOUR         = hour
		collections.TIME_MIN          = minute
		collections.TIME_MON          = month
		collections.TIME_SEC          = second
		collections.TIME_YEAR         = year
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
			collections.RESPONSE_BODY = table_concat(ctx.buffers, '')
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
	cmd_line = function(waf, value)
		local str = tostring(value)
		str = ngx.re.gsub(str, [=[[\\'"^]]=], '',  waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+/]=],    '/', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+[(]]=],  '(', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[[,;]]=],    ' ', waf._pcre_flags)
		str = ngx.re.gsub(str, [=[\s+]=],     ' ', waf._pcre_flags)
		return string_lower(str)
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
		str = ngx.re.gsub(str, [=[&#(\d+);]=], function(n) return string_char(n[1]) end, waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&#x(\d+);]=], function(n) return string_char(tonumber(n[1],16)) end, waf._pcre_flags)
		str = ngx.re.gsub(str, [=[&amp;]=], '&', waf._pcre_flags)
		logger.log(waf, "html decoded value is " .. str)
		return str
	end,
	length = function(waf, value)
		return string_len(tostring(value))
	end,
	lowercase = function(waf, value)
		return string_lower(tostring(value))
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
		if (string_find(value, '0x', 1, true)) then
			value = string_sub(value, 3)
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

return _M
