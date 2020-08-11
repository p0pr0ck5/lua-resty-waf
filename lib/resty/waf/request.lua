local ffi = require 'ffi'
local base = require "resty.core.base"
local utils = require "resty.core.utils"


local FFI_BAD_CONTEXT = base.FFI_BAD_CONTEXT
local C = ffi.C
local ffi_cast = ffi.cast
local ffi_new = ffi.new
local ffi_str = ffi.string
local get_request = base.get_request
local get_string_buf = base.get_string_buf
local get_size_ptr = base.get_size_ptr
local lower = string.lower
local new_tab = base.new_tab
local str_replace_char = utils.str_replace_char


local table_elt_type = ffi.typeof("ngx_http_lua_ffi_table_elt_t*")
local table_elt_size = ffi.sizeof("ngx_http_lua_ffi_table_elt_t")
local truncated = ffi.new("int[1]")


local req_headers_mt = {
    __index = function (tb, key)
        return rawget(tb, (str_replace_char(lower(key), '_', '-')))
    end
}


local request = {}


function request.get_headers(max_headers, raw)
    local r = get_request()
    if not r then
        error("no request found")
    end

    if not max_headers then
        max_headers = -1
    end

    if not raw then
        raw = 0
    else
        raw = 1
    end

    local n = C.ngx_http_lua_ffi_req_get_headers_count(r, max_headers,
                                                       truncated)
    if n == FFI_BAD_CONTEXT then
        error("API disabled in the current context", 2)
    end

    if n == 0 then
        local headers = {}
        if raw == 0 then
            headers = setmetatable(headers, req_headers_mt)
        end

        return headers
    end

    local raw_buf = get_string_buf(n * table_elt_size)
    local buf = ffi_cast(table_elt_type, raw_buf)

    local rc = C.ngx_http_lua_ffi_req_get_headers(r, buf, n, raw)
    if rc == 0 then
        local headers, headers_complex = new_tab(0, n), new_tab(n, 0)
        for i = 0, n - 1 do
            local h = buf[i]

            local key = h.key
            key = ffi_str(key.data, key.len)

            local value = h.value
            value = ffi_str(value.data, value.len)

            headers_complex[#headers_complex+1] = { key = key, value = value }

            local existing = headers[key]
            if existing then
                if type(existing) == "table" then
                    existing[#existing + 1] = value
                else
                    headers[key] = {existing, value}
                end

            else
                headers[key] = value
            end
        end

        if raw == 0 then
            headers = setmetatable(headers, req_headers_mt)
        end

        if truncated[0] ~= 0 then
            return headers, "truncated"
        end

        return headers, headers_complex
    end

    return nil
end


function request.get_uri_args(max_args)
    local r = get_request()
    if not r then
        error("no request found")
    end

    if not max_args then
        max_args = -1
    end

    local n = C.ngx_http_lua_ffi_req_get_uri_args_count(r, max_args, truncated)
    if n == FFI_BAD_CONTEXT then
        error("API disabled in the current context", 2)
    end

    if n == 0 then
        return {}, {}
    end

    local args_len = C.ngx_http_lua_ffi_req_get_querystring_len(r)

    local strbuf = get_string_buf(args_len + n * table_elt_size)
    local kvbuf = ffi_cast(table_elt_type, strbuf + args_len)

    local nargs = C.ngx_http_lua_ffi_req_get_uri_args(r, strbuf, kvbuf, n)

    local args, args_complex = new_tab(0, nargs), new_tab(nargs, 0)
    for i = 0, nargs - 1 do
        local arg = kvbuf[i]

        local key = arg.key
        key = ffi_str(key.data, key.len)

        local value = arg.value
        local len = value.len
        if len == -1 then
            value = true
        else
            value = ffi_str(value.data, len)
        end

        args_complex[#args_complex+1] = { key = key, value = value }

        local existing = args[key]
        if existing then
            if type(existing) == "table" then
                existing[#existing + 1] = value
            else
                args[key] = {existing, value}
            end

        else
            args[key] = value
        end
    end

    if truncated[0] ~= 0 then
        return args, "truncated"
    end

    return args, args_complex
end


return request