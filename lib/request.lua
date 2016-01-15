local _M = {}

_M.version = "0.5.2"

local cookiejar = require("inc.resty.cookie")
local upload    = require("inc.resty.upload")

local logger = require("lib.log")
local util   = require("lib.util")

function _M.parse_request_body(FW, request_headers)
	local content_type_header = request_headers["content-type"]

    -- multiple content-type headers are likely an evasion tactic
    -- or result from misconfigured proxies. may consider relaxing
    -- this or adding an option to disable this checking in the future
    if (type(content_type_header) == "table") then
        logger.log(FW, "request contained multiple content-type headers, bailing!")
        ngx.exit(400)
    end

    -- ignore the request body if no Content-Type header is sent
    -- this does technically violate the RFC
    -- but its necessary for us to properly handle the request
    -- and its likely a sign of nogoodnickery anyway
    if (not content_type_header) then
        logger.log(FW, "request has no content type, ignoring the body")
        ngx.req.discard_body()
        return
    end

    -- handle the request body based on the Content-Type header
    -- multipart/form-data requests will be streamed in via lua-resty-upload,
    -- which provides some basic sanity checking as far as form and protocol goes
    -- (but its much less strict that ModSecurity's strict checking)
    if (ngx.re.find(content_type_header, [=[^multipart/form-data; boundary=]=], FW._pcre_flags)) then
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
    elseif (content_type_header == "application/x-www-form-urlencoded") then
        -- use the underlying ngx API to read the request body
        -- ignore processing the request body if the content length is larger than client_body_buffer_size
        -- to avoid wasting resources on ruleset matching of very large data sets
        ngx.req.read_body()
        if (ngx.req.get_body_file() == nil) then
            return ngx.req.get_post_args()
        else
            logger.log(FW, "very large form upload, not parsing")
			ngx.exit(ngx.OK)
        end
    elseif (util.table_has_value(FW, content_type_header, FW._allowed_content_types)) then
        -- users can whitelist specific content types that will be passed in but not parsed
        -- read the request in, but don't set collections[REQUEST_BODY]
        -- as we have no way to know what kind of data we're getting (i.e xml/json/octet stream)
        ngx.req.read_body()
        return nil
    else
        logger.log(FW, tostring(content_type_header) .. " not a valid content type!")
		ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

function _M.cookies()
	local cookies = cookiejar:new()
	local request_cookies, cookie_err = cookies:get_all()

	return request_cookies
end

-- return a single table from multiple tables containing request data
function _M.common_args(FW, collections)
    local t = {}

    for _, collection in pairs(collections) do
        if (collection ~= nil) then
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
                logger.log(FW, "t[" .. k .. "] contains " .. tostring(t[k]))
            end
        end
    end

    return t
end

return _M
