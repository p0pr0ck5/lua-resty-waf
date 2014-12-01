local _M = {}

_M.version = "0.0.5"

require("logging.file")
local cjson = require("cjson")
local cookiejar = require("resty.cookie")
local ffi = require("ffi")
local logger = logging.file('/var/log/freewaf/fw.log')

-- microsecond precision
ffi.cdef[[
	typedef long time_t;

	typedef struct timeval {
		time_t tv_sec;
		time_t tv_usec;
	} timeval;

	int gettimeofday(struct timeval* t, void* tzp);
]]

local function gettimeofday()
	local gettimeofday_struct = ffi.new("timeval")
	ffi.C.gettimeofday(gettimeofday_struct, nil)
	return tonumber(gettimeofday_struct.tv_sec) * 1000000 + tonumber(gettimeofday_struct.tv_usec)
end

-- eventually this goes away in the name of performance
logger:setLevel(logging.DEBUG)

-- sanity check
local allowed_modes = { "INACTIVE", "DEBUG", "ACTIVE" }

-- used for operators.EXISTS
local function _equals(a, b)
	local equals
	if (type(a) == "table") then
		logger:debug("Needle is a table, so recursing!")
		for _, v in ipairs(a) do
			equals = _equals(v, b)
			if (equals) then
				break
			end
		end
	else
		logger:info("Comparing " .. a .. " and " .. b)
		equals = a == b
	end

	return equals
end

-- used for operators.NOT_EXISTS
local function _not_equals(a, b)
	return not _equals(a, b)
end

-- strips an ending newline
local function _trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- ngx.req.raw_header() gets us the raw HTTP header with newlines included
-- so we need to get the first line and trim it down
local function _get_request_line()
	local raw_header = ngx.req.raw_header()
	local t = {}
	local n = 0
	for token in string.gmatch(raw_header, "[^\n]+") do -- look into switching to string.match instead
		n = n + 1
		t[n] = token
	end

	return _trim(t[1])
end

-- duplicate a table using recursion if necessary for multi-dimensional tables
-- useful for getting a local copy of a table
local function _table_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_table_copy(orig_key)] = _table_copy(orig_value)
        end
        setmetatable(copy, _table_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- return a table containing the keys of the provided table
local function _table_keys(table)
	local t = {}
	local n = 0
	
	for key, _ in pairs(table) do
		n = n + 1
		t[n] = tostring(key) -- tostring is probably too large a hammer
	end
	
	return t
end

-- return a table containing the values of the provided table
local function _table_values(table)
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
local function _table_has_key(needle, haystack)
	if (type(haystack) ~= "table") then
		_fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end
	logger:debug("table key " .. needle .. "is " .. tostring(haystack[needle]))
	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
local function _table_has_value(needle, haystack)
	logger:debug("Searching for " .. needle)

	if (type(haystack) ~= "table") then
		_fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		logger:debug("Checking " .. value)
		if (value == needle) then return true end
	end
end

-- inverse of fw.table_has_value
local function _table_not_has_value(needle, value)
	return not _table_has_value(needle, value)
end

-- remove all values from a table
local function _table_clear(t)
	if (type(t) ~= "table") then
		logger:error("table_clear wasn't provided a table! Bailing...")
		return t
	end

	for k in ipairs(t) do
		t[k] = nil
	end

	return t
end

-- regex matcher (uses POSIX patterns via ngx.re.match)
local function _regex_match(subject, pattern, opts)
	local opts = "oij"
	local from, to, err
	local match

	if (type(subject) == "table") then
		logger:debug("subject is a table, so recursing!")
		for _, v in ipairs(subject) do
			match = _regex_match(v, pattern, opts)
			if (match) then
				break
			end
		end
	else
		logger:debug("matching " .. subject .. " against " .. pattern)
		from, to, err = ngx.re.find(subject, pattern, opts)
		if err then logger:error("error in waf.regexmatch: " .. err) end
		if from then
			logger:debug("regex match! " .. string.sub(subject, from, to))
			match = string.sub(subject, from, to)
		end
	end

	return match
end

local function _parse_collection(collection, opts)
	local lookup = {
		specific = function(collection, value)
			logger:debug("_parse_collection is getting a specific value: " .. value)
			return collection[value]
		end,
		ignore = function(collection, value)
			logger:debug("_parse_collection is ignoring a value: " .. value)
			local _collection = {}
			_collection = _table_copy(collection)
			_collection[value] = nil
			return _collection
		end,
		keys = function(collection)
			logger:debug("_parse_collection is getting the keys")
			return _table_keys(collection)
		end,
		values = function(collection)
			logger:debug("_parse_collection is getting the values")
			return _table_values(collection)
		end
	}

	if (type(collection) ~= "table") then
		return collection
	end

	if (opts == nil) then
		return collection
	end

	return lookup[opts.key](collection, opts.value)
end

local function _build_common_args(collections)
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
				logger:debug("t[" .. k .. "] contains " .. tostring(t[k]))
			end
		end
	end

	return t
end

-- if we need to bail, 503 is distinguishable from the 500 that gets thrown from a lua failure
local function _fatal_fail(msg)
	logger:fatal("fatal_fail called with the following: " .. msg)
	ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

local function _log_event(request_client, request_uri, rule, match)
	local t = {
		client = request_client,
		uri = request_uri,
		rule = rule,
		match = match
	}

	ngx.log(ngx.WARN, cjson.encode(t))

	logger:warn("EVENT LOGGED! " .. rule.id)
end

-- debug
local function _finish(start)
	local finish = gettimeofday()
	logger:warn("Finished fw.exec in: " .. finish - start)
end

-- module-level table to define rule operators
-- no need to recreated this with every request
local operators = {
	REGEX = function(subject, pattern, opts) return _regex_match(subject, pattern, opts) end,
	NOT_REGEX = function(subject, pattern, opts) return not _regex_match(subject, pattern, opts) end,
	EQUALS = function(a, b) return _equals(a, b) end,
	NOT_EQUALS = function(a, b) return _not_equals(a, b) end,
	EXISTS = function(haystack, needle) return _table_has_value(needle, haystack) end,
	NOT_EXISTS = function(haystack, needle) return _table_not_has_value(needle, haystack) end,
}

-- module-level table to define rule actions
-- this may get changed if/when heuristics gets introduced
local actions = {
	LOG = function() 
		logger:debug("rule.action was LOG, since we already called log_event this is relatively meaningless")
		--fw.finish()
	end,
	DENY = function(start)
		logger:debug("rule.action was DENY, so telling nginx to quit!")
		_finish(start)
		ngx.exit(ngx.HTTP_FORBIDDEN)
	end,
	IGNORE = function()
		logger:debug("Ingoring rule for now")
	end
}

-- use the lookup table to figure out what to do
local function _rule_action(action, start)
	logger:info("Taking the following action: " .. action)
	actions[action](start)
end

local function _process_rule(rule, collections, ctx)
	local id = rule.id
	local var = rule.var
	local opts = rule.opts
	local action = rule.action
	local description = rule.description

	if (opts.chainchild == true and ctx.chained == false) then
		logger:info("This is a chained rule, but we don't have a previous match, so not processing")
		return
	end

	logger:debug("parsing collections for rule " .. id)
	local t = _parse_collection(collections[var.type], var.opts)

	if (not t) then
		logger:info("parse_collection didnt return anything for " .. var.type)
	else
		local match = operators[var.operator](t, var.pattern)
		if (match) then
			logger:info("Match of rule " .. id .. "!")
			if (action == "CHAIN") then
				ctx.chained = true
				logger:info("CHAIN parent matched, moving on to the next rule")
				return
			end

			if (not opts.nolog) then
				_log_event(request_client, request_uri, rule, match)
			else
				logger:info("We had a match, but not logging because opts.nolog is set")
			end

			if (ctx.mode == "ACTIVE") then
				_rule_action(action, ctx.start)
			end
		end
	end

	if (opts.chainend == true) then
		ctx.chained = false
	end
end

-- main entry point
-- data associated with a given request in kept local in scope to this function
-- because the lua api only loads this module once, so module-level variables
-- can be cross-polluted
function _M.exec(opts)
	local start = gettimeofday()
	logger:debug("Request started: " .. ngx.req.start_time())

	if (type(opts) ~= "table") then
		_fatal_fail("opts is not a table, it is a " .. type(opts))
	end

	-- more sanity checks
	local mode = opts.mode
	if (mode == "INACTIVE") then
		logger:info("Operational mode is INACTIVE, not running")
		return
	end

	if (not _table_has_value(opts.mode, allowed_modes)) then
		_fatal_fail("Invalid operational mode provided: " .. tostring(mode))
	end

	local user_id = opts.user_id
	local active_rulesets = opts.active_rulesets
	local ignored_rules = opts.ignored_rules
	local allowed_methods = opts.allowed_methods

	local request_client = ngx.var.remote_addr
	local request_http_version = ngx.req.http_version()
	local request_method = ngx.req.get_method()
	local request_uri = ngx.var.uri
	local request_uri_args = ngx.req.get_uri_args()
	local request_headers = ngx.req.get_headers()
	local request_ua = ngx.var.http_user_agent
	local request_request_line = _get_request_line()

	logger:debug("Comparing " .. request_client  .. " against whitelist")
	if _table_has_value(request_client, opts.whitelist) then
		logger:info("Allowing " .. request_client .. " because of whitelist")
		ngx.exit(ngx.OK) -- exiting with OK passes to the next phase handler
	end

	logger:info("Handling a " .. request_method .. " request to " .. request_uri)

	if (not _table_has_value(request_method, allowed_methods)) then
		if (mode == "ACTIVE") then
			_rule_action("DENY") -- special case since this isn't a rule, but we should still follow the proper chain
		end
	end


	-- if we were POSTed to, read the body in, otherwise trash it (don't ignore it!)
	-- we'll have a rule about body content with a GET, which brings up 2 questions:
	-- 1. should we make this explicitly POST only, or just non-GET
	-- 2. should we allow GETs with body, if it's going to be in the ruleset (GET w/ body doesn't violate rfc2616)
	if (request_method ~= "POST") then
		ngx.req.discard_body()
		request_post_args = nil
	else
		ngx.req.read_body()

		-- workaround for now. if we buffered to disk, skip it
		if (ngx.req.get_body_file() == nil) then
			request_post_args = ngx.req.get_post_args()
		else
			logger:warn("Skipping POST arguments because we buffered to disk")
			logger:warn(ngx.req.get_body_file())
		end
	end

	local cookies = cookiejar:new() -- resty.cookie
	local request_cookies, cookie_err = cookies:get_all()
	if not request_cookies then
		logger:warn("could not get cookies: " .. cookie_err)
	end
	local request_common_args = _build_common_args({ request_uri_args, request_post_args, request_cookies })

	-- link rule collections to request data
	-- unlike the operators and actions lookup table,
	-- this needs data specific to each individual request
	-- so we have to instantiate it here
	local collections = {
		CLIENT = request_client,
		HTTP_VERSION = request_http_version,
		METHOD = request_method,
		URI = request_uri,
		URI_ARGS = request_uri_args,
		HEADERS = request_headers,
		HEADER_NAMES = _table_keys(request_headers),
		USER_AGENT = request_ua,
		REQUEST_LINE = request_request_line,
		COOKIES = request_cookies,
		REQUEST_BODY = request_post_args,
		REQUEST_ARGS = request_common_args
	}

	local ctx = {}
	ctx.mode = mode
	ctx.start = start

	for _, ruleset in ipairs(active_rulesets) do
		logger:info("Beginning ruleset " .. ruleset)

		logger:debug("Requiring rs_" .. ruleset)
		local rs = require("fw_rules.rs_" .. ruleset)

		for __, rule in ipairs(rs.rules()) do
			if (not _table_has_value(rule.id, ignored_rules)) then
				logger:debug("Beginning run of rule " .. rule.id)
				_process_rule(rule, collections, ctx)
			else
				logger:info("Ignoring rule " .. rule.id)
			end
		end
	end

	_finish(start)
end -- fw.exec()

return _M
