local _M = {}

_M.version = "0.7.0"

local cookiejar = require("inc.resty.cookie")
local upload	= require("inc.resty.upload")

local logger = require("lib.log")
local util   = require("lib.util")

function _M.parse_request_body(waf, request_headers)
	local content_type_header = request_headers["content-type"]

	-- multiple content-type headers are likely an evasion tactic
	-- or result from misconfigured proxies. may consider relaxing
	-- this or adding an option to disable this checking in the future
	if (type(content_type_header) == "table") then
		logger.log(waf, "Request contained multiple content-type headers, bailing!")
		ngx.exit(400)
	end

	-- ignore the request body if no Content-Type header is sent
	-- this does technically violate the RFC
	-- but its necessary for us to properly handle the request
	-- and its likely a sign of nogoodnickery anyway
	if (not content_type_header) then
		logger.log(waf, "Request has no content type, ignoring the body")
		return nil
	end

	-- handle the request body based on the Content-Type header
	-- multipart/form-data requests will be streamed in via lua-resty-upload,
	-- which provides some basic sanity checking as far as form and protocol goes
	-- (but its much less strict that ModSecurity's strict checking)
	if (ngx.re.find(content_type_header, [=[^multipart/form-data; boundary=]=], waf._pcre_flags)) then
		if (not waf._process_multipart_body) then
			return
		end

		local form, err = upload:new()
		if not form then
			ngx.log(ngx.ERR, "failed to parse multipart request: ", err)
			ngx.exit(400) -- may move this into a ruleset along with other strict checking
		end

		ngx.req.init_body()
		form:set_timeout(1000)

		-- initial boundary
		ngx.req.append_body("--" .. form.boundary)

		-- this is gonna need some tlc, but it seems to work for now
		local lasttype, chunk
		while true do
			local typ, res, err = form:read()
			if not typ then
				logger.fatal_fail("failed to stream request body: " .. err)
			end

			if (typ == "header") then
				chunk = res[3] -- form:read() returns { key, value, line } here
				ngx.req.append_body("\n" .. chunk)
			elseif (typ == "body") then
				chunk = res
				if (lasttype == "header") then
					ngx.req.append_body("\n\n")
				end
				ngx.req.append_body(chunk)
			elseif (typ == "part_end") then
				ngx.req.append_body("\n--" .. form.boundary)
			elseif (typ == "eof") then
				ngx.req.append_body("--\n")
				break
			end

			lasttype = typ
		end

		-- lua-resty-upload docs use one final read, i think it's needed to get
		-- the last part of the data off the socket
		form:read()
		ngx.req.finish_body()

		return nil
	elseif (ngx.re.find(content_type_header, [=[^application/x-www-form-urlencoded]=], waf._pcre_flags)) then
		-- use the underlying ngx API to read the request body
		-- ignore processing the request body if the content length is larger than client_body_buffer_size
		-- to avoid wasting resources on ruleset matching of very large data sets
		ngx.req.read_body()

		if (ngx.req.get_body_file() == nil) then
			return ngx.req.get_post_args()
		else
			logger.log(waf, "Request body size larger than client_body_buffer_size, ignoring request body")
			return nil
		end
	elseif (util.table_has_key(content_type_header, waf._allowed_content_types)) then
		-- if the content type has been whitelisted by the user, set REQUEST_BODY as a string
		ngx.req.read_body()

		if (ngx.req.get_body_file() == nil) then
			return ngx.req.get_body_data()
		else
			logger.log(waf, "Request body size larger than client_body_buffer_size, ignoring request body")
			return nil
		end
	else
		if (waf._allow_unknown_content_types) then
			logger.log(waf, "Allowing request with content type " .. tostring(content_type_header))
			return nil
		else
			logger.log(waf, tostring(content_type_header) .. " not a valid content type!")
			ngx.exit(ngx.HTTP_FORBIDDEN)
		end
	end
end

function _M.request_uri()
	local request_line = {}
	local is_args      = ngx.var.is_args

	request_line[1] = ngx.var.uri

	if (is_args) then
		request_line[2] = is_args
		request_line[3] = ngx.var.query_string
	end

	return table.concat(request_line, '')
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
function _M.common_args(waf, collections)
	local t = {}

	for _, collection in pairs(collections) do
		if (type(collection) == "table") then
			for k, v in pairs(collection) do
				if (t[k] == nil) then
					t[k] = v
				else
					if (type(t[k]) == "table") then
						table.insert(t[k], v)
					else
						local _v = t[k]
						t[k] = { _v, v }
					end
				end
				logger.log(waf, "t[" .. k .. "] contains " .. tostring(t[k]))
			end
		end
	end

	return t
end

return _M
