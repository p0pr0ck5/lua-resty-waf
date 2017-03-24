local _M = {}

local cookiejar = require "resty.cookie"
local upload	= require "resty.upload"

local base   = require "resty.waf.base"
local logger = require "resty.waf.log"
local util   = require "resty.waf.util"

local table_concat = table.concat
local table_insert = table.insert

_M.version = base.version

function _M.parse_request_body(waf, request_headers, collections)
	local content_type_header = request_headers["content-type"]

	-- multiple content-type headers are likely an evasion tactic
	-- or result from misconfigured proxies. may consider relaxing
	-- this or adding an option to disable this checking in the future
	if type(content_type_header) == "table" then
		--_LOG_"Request contained multiple content-type headers, bailing!"
		ngx.exit(400)
	end

	-- ignore the request body if no Content-Type header is sent
	-- this does technically violate the RFC
	-- but its necessary for us to properly handle the request
	-- and its likely a sign of nogoodnickery anyway
	if not content_type_header then
		--_LOG_"Request has no content type, ignoring the body"
		return nil
	end

	--_LOG_"Examining content type " .. content_type_header

	-- handle the request body based on the Content-Type header
	-- multipart/form-data requests will be streamed in via lua-resty-upload,
	-- which provides some basic sanity checking as far as form and protocol goes
	-- (but its much less strict that ModSecurity's strict checking)
	if ngx.re.find(content_type_header, [=[^multipart/form-data; boundary=]=], waf._pcre_flags) then
		if not waf._process_multipart_body then
			return
		end

		local form, err = upload:new()
		if not form then
			logger.warn(waf, "failed to parse multipart request: ", err)
			ngx.exit(400) -- may move this into a ruleset along with other strict checking
		end

		local FILES = {}
		local FILES_NAMES = {}
		local FILES_SIZES = {}
		local FILES_TMP_CONTENT = {}

		ngx.req.init_body()
		form:set_timeout(1000)

		-- initial boundary
		ngx.req.append_body("--" .. form.boundary)

		-- this is gonna need some tlc, but it seems to work for now
		local lasttype, chunk, file, body, body_size, files_size
		files_size = 0
		body_size  = 0
		body = ''
		while true do
			local typ, res, err = form:read()
			if not typ then
				logger.fatal_fail("failed to stream request body: " .. err)
			end

			if typ == "header" then
				ngx.log(ngx.DEBUG, res[1]:lower())

				if res[1]:lower() == 'content-disposition' then
					local header = res[2]

					local s, f = header:find(' name="([^"]+")')
					file = header:sub(s + 7, f - 1)
					table.insert(FILES_NAMES, file)

					s, f = header:find('filename="([^"]+")')
					if s then table.insert(FILES, header:sub(s + 10, f - 1)) end
				end

				chunk = res[3] -- form:read() returns { key, value, line } here
				ngx.req.append_body("\r\n" .. chunk)
			elseif typ == "body" then
				chunk = res
				if lasttype == "header" then
					ngx.req.append_body("\r\n\r\n")
				end

				local chunk_size = #chunk

				body = body .. chunk
				body_size = body_size + #chunk

				--_LOG_"c:" .. chunk_size .. ", b:" .. body_size

				ngx.req.append_body(chunk)
			elseif typ == "part_end" then
				table.insert(FILES_SIZES, body_size)
				files_size = files_size + body_size
				body_size = 0

				FILES_TMP_CONTENT[file] = body
				body = ''

				ngx.req.append_body("\r\n--" .. form.boundary)
			elseif typ == "eof" then
				ngx.req.append_body("--\r\n")
				break
			end

			lasttype = typ
		end

		-- lua-resty-upload docs use one final read, i think it's needed to get
		-- the last part of the data off the socket
		form:read()
		ngx.req.finish_body()

		collections.FILES = FILES
		collections.FILES_NAMES = FILES_NAMES
		collections.FILES_SIZES = FILES_SIZES
		collections.FILES_TMP_CONTENT = FILES_TMP_CONTENT
		collections.FILES_COMBINED_SIZE = files_size

		return nil
	elseif ngx.re.find(content_type_header, [=[^application/x-www-form-urlencoded]=], waf._pcre_flags) then
		-- use the underlying ngx API to read the request body
		-- ignore processing the request body if the content length is larger than client_body_buffer_size
		-- to avoid wasting resources on ruleset matching of very large data sets
		ngx.req.read_body()

		if ngx.req.get_body_file() == nil then
			return ngx.req.get_post_args()
		else
			--_LOG_"Request body size larger than client_body_buffer_size, ignoring request body"
			return nil
		end
	elseif util.table_has_key(content_type_header, waf._allowed_content_types) then
		-- if the content type has been whitelisted by the user, set REQUEST_BODY as a string
		ngx.req.read_body()

		if ngx.req.get_body_file() == nil then
			return ngx.req.get_body_data()
		else
			--_LOG_"Request body size larger than client_body_buffer_size, ignoring request body"
			return nil
		end
	else
		if waf._allow_unknown_content_types then
			--_LOG_"Allowing request with content type " .. tostring(content_type_header)
			return nil
		else
			--_LOG_tostring(content_type_header) .. " not a valid content type!"
			ngx.exit(ngx.HTTP_FORBIDDEN)
		end
	end
end

function _M.request_uri()
	local request_line = {}
	local is_args      = ngx.var.is_args

	request_line[1] = ngx.var.uri

	if is_args then
		request_line[2] = is_args
		request_line[3] = ngx.var.query_string
	end

	return table_concat(request_line, '')
end

function _M.request_uri_raw(request_line, method)
	return string.sub(request_line, #method + 2, -10)
end

function _M.basename(waf, uri)
	local m = ngx.re.match(uri, [=[(/[^/]*+)+]=], waf._pcre_flags)
	return m[1]
end

function _M.cookies()
	local cookies = cookiejar:new()
	local request_cookies, cookie_err = cookies:get_all()

	return request_cookies
end

-- return a single table from multiple tables containing request data
-- note that collections that are not a table (e.g. REQUEST_BODY with
-- a non application/x-www-form-urlencoded content type) are ignored
function _M.common_args(collections)
	local t = {}

	for _, collection in pairs(collections) do
		if type(collection) == "table" then
			for k, v in pairs(collection) do
				if t[k] == nil then
					t[k] = v
				else
					if type(t[k]) == "table" then
						table_insert(t[k], v)
					else
						local _v = t[k]
						t[k] = { _v, v }
					end
				end
			end
		end
	end

	return t
end

return _M
