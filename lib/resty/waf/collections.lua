local _M = {}

_M.version = "0.9"

local logger    = require "resty.waf.log"
local request   = require "resty.waf.request"
local util      = require "resty.waf.util"

local string_format = string.format
local string_match  = string.match
local table_concat  = table.concat

_M.lookup = {
	access = function(waf, collections, ctx)
		local request_headers     = ngx.req.get_headers()
		local request_uri_args    = ngx.req.get_uri_args()
		local request_uri         = request.request_uri()
		local request_basename    = request.basename(waf, ngx.var.uri)
		local request_body        = request.parse_request_body(waf, request_headers)
		local request_cookies     = request.cookies() or {}
		local request_common_args = request.common_args({ request_uri_args, request_body, request_cookies })

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
	end,
	log = function() end
}

return _M
