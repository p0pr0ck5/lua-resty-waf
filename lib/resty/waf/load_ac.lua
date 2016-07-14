-- Helper wrappring script for loading shared object libac.so (FFI interface)
-- from package.cpath instead of LD_LIBRARTY_PATH.
--

local ffi = require 'ffi'
ffi.cdef[[
  void* ac_create(const char** str_v, unsigned int* strlen_v,
                  unsigned int v_len);
  int ac_match2(void*, const char *str, int len);
  void ac_free(void*);
]]

local _M = {}

local string_gmatch = string.gmatch
local string_match = string.match

local ac_lib = nil
local ac_create = nil
local ac_match = nil
local ac_free = nil

--[[ Find shared object file package.cpath, obviating the need of setting
   LD_LIBRARY_PATH
]]
local function find_shared_obj(cpath, so_name)
    for k, v in string_gmatch(cpath, "[^;]+") do
        local so_path = string_match(k, "(.*/)")
        if so_path then
            -- "so_path" could be nil. e.g, the dir path component is "."
            so_path = so_path .. so_name

            -- Don't get me wrong, the only way to know if a file exist is
            -- trying to open it.
            local f = io.open(so_path)
            if f ~= nil then
                io.close(f)
                return so_path
            end
        end
    end
end

function _M.load_ac_lib()
    if ac_lib ~= nil then
        return ac_lib
    else
        local so_path = find_shared_obj(package.cpath, "libac.so")
        if so_path ~= nil then
            ac_lib = ffi.load(so_path)
            ac_create = ac_lib.ac_create
            ac_match = ac_lib.ac_match2
            ac_free = ac_lib.ac_free
            return ac_lib
        end
    end
end

-- Create an Aho-Corasick instance, and return the instance if it was
-- successful.
function _M.create_ac(dict)
    local strnum = #dict
    if ac_lib == nil then
        _M.load_ac_lib()
    end

    local str_v = ffi.new("const char *[?]", strnum)
    local strlen_v = ffi.new("unsigned int [?]", strnum)

    for i = 1, strnum do
        local s = dict[i]
        str_v[i - 1] = s
        strlen_v[i - 1] = #s
    end

    local ac = ac_create(str_v, strlen_v, strnum);
    if ac ~= nil then
        return ffi.gc(ac, ac_free)
    end
end

-- Return nil if str doesn't match the dictionary, else return non-nil.
function _M.match(ac, str)
    local r = ac_match(ac, str, #str);
    if r >= 0 then
        return r
    end
end

return _M
