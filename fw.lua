local fw = {}

-- microsecond precision
local ffi = require("ffi")
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

local cookiejar = require "resty.cookie"
local cjson = require "cjson"

-- eventually this goes away in the name of performance
require("logging.file")
local logger = logging.file('/var/log/freewaf/fw.log')
logger:setLevel(logging.DEBUG)

-- module-level table to define rule operators
-- no need to recreated this with every request
local operators = {
	REGEX = function(subject, pattern, opts) return fw.regex_match(subject, pattern, opts) end,
	NOT_REGEX = function(subject, pattern, opts) return not fw.regex_match(subject, pattern, opts) end,
	EQUALS = function(a, b) return fw.equals(a, b) end,
	NOT_EQUALS = function(a, b) return fw.not_equals(a, b) end,
	EXISTS = function(haystack, needle) return fw.table_has_value(needle, haystack) end,
	NOT_EXISTS = function(haystack, needle) return fw.table_not_has_value(needle, haystack) end,
	FALSE = function() logger:warn("operator was FALSE!!! Check the rule to see why!"); return false end,
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
		fw.finish(start)
		ngx.exit(ngx.HTTP_FORBIDDEN)
	end,
	IGNORE = function()
		logger:debug("Ingoring rule for now")
	end
}

-- sanity check
local allowed_modes = { "INACTIVE", "DEBUG", "ACTIVE" }

-- used for operators.EXISTS
function fw.equals(a, b)
	local equals
	if (type(a) == "table") then
		logger:debug("Needle is a table, so recursing!")
		for _, v in ipairs(a) do
			equals = fw.equals(v, b)
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
function fw.not_equals(a, b)
	return not fw.equals(a, b)
end

-- ngx.req.raw_header() gets us the raw HTTP header with newlines included
-- so we need to get the first line and trim it down
function fw.get_request_line()
	local raw_header = ngx.req.raw_header()
	local t = {}
	local n = 0
	for token in string.gmatch(raw_header, "[^\n]+") do -- look into switching to string.match instead
		n = n + 1
		t[n] = token
	end

	return fw.trim(t[1])
end

-- strips an ending newline
function fw.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- duplicate a table using recursion if necessary for multi-dimensional tables
-- useful for getting a local copy of a table
function fw.table_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[fw.table_copy(orig_key)] = fw.table_copy(orig_value)
        end
        setmetatable(copy, fw.table_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- return a table containing the keys of the provided table
function fw.table_keys(table)
	local t = {}
	local n = 0
	
	for key, _ in pairs(table) do
		n = n + 1
		t[n] = tostring(key) -- tostring is probably too large a hammer
	end
	
	return t
end

-- return a table containing the values of the provided table
function fw.table_values(table)
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
function fw.table_has_key(needle, haystack)
	if (type(haystack) ~= "table") then
		fw.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end
	logger:debug("table key " .. needle .. "is " .. tostring(haystack[needle]))
	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
function fw.table_has_value(needle, haystack)
	logger:debug("Searching for " .. needle)

	if (type(haystack) ~= "table") then
		fw.fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		logger:debug("Checking " .. value)
		if (value == needle) then return true end
	end
end

-- inverse of fw.table_has_value
function fw.table_not_has_value(needle, value)
	return not fw.table_has_value(needle, value)
end

-- remove all values from a table
function fw.table_clear(t)
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
function fw.regex_match(subject, pattern, opts)
	local opts = "oij"
	local from, to, err
	local match

	if (type(subject) == "table") then
		logger:debug("subject is a table, so recursing!")
		for _, v in ipairs(subject) do
			match = fw.regex_match(v, pattern, opts)
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

-- return a subset of a collection based on the options provided
function fw.parse_collection(collection, opts)
	local t

	if (type(collection) ~= "table") then
		logger:info("parse_collection was sent a " .. type(collection) .. " instead of a collection table, creating a new table for " .. tostring(collection))
		return { collection }, ""
	end

	if (type(opts) ~= "table") then
		logger:warn("parse_collection was sent " .. tostring(opts) .. " (a " .. type(opts) .. ") instead of an opts table, so setting it to nil")
		opts = nil
	end

	if (opts == nil) then
		return collection, ""
	end

	if (opts.specific ~= nil) then
		return collection[opts.specific], ":" .. opts.specific
	end

	if (opts.ignore ~= nil) then
		t = fw.table_copy(collection)
		if (t[opts.ignore] ~= nil) then
			t[opts.ignore] = nil
		end
		return fw.table_values(t), ":!" .. opts.ignore -- if we just return t we potentially get a table with non-integer keys
	end

	if (opts.keys ~= nil) then
		return fw.table_keys(collection), ":keys"
	end

	if (opts.values ~= nil) then
		return fw.table_values(collection), ":values"
	end

	if (opts.all ~= nil) then
		local n = 0
		t = {}

		-- need to get keys and values separate in case a key was duplicated (the value would be a table)
		for _, key in ipairs(fw.table_keys(collection)) do
			n = n + 1
			t[n] = key
			logger:debug("parse_collection local table t[" .. n .. "]: " .. t[n])
		end
		for _,value in ipairs(fw.table_values(collection)) do
			n = n + 1
			t[n] = value
			logger:debug("parse_collection local table t[" .. n .. "]: " .. t[n])
		end
		return t, ":all"
	end

	-- maybe need to look at alternatives to falling all the way through
	logger:debug("No opts and collection was a table, so just getting the whole thing " .. tostring(collection))
	return collection, ""
end

-- COMMON_ARGS holds request params including GET and POST params, and cookies
function fw._build_common_args(colls)
	local t = {}
	local n = 0
	for _, c in pairs(colls) do
		if (c ~= nil) then
			for _, key in ipairs(fw.table_keys(c)) do
        	    n = n + 1 
            	t[n] = key 
	            logger:debug("common_args local table t[" .. n .. "]: " .. t[n])
    	    end 
        	for _,value in ipairs(fw.table_values(c)) do
            	n = n + 1 
	            t[n] = value
    	        logger:debug("common_args local table t[" .. n .. "]: " .. t[n])
        	end 
		else
			logger:info("nil table!")
		end
	end
	return t
end

function fw.build_common_args(collections)
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

-- use the lookup table to figure out what to do
function fw.rule_action(action, start)
	logger:info("Taking the following action: " .. action)
	local _ = actions[action](start)
end

-- if we need to bail, 503 is distinguishable from the 500 that gets thrown from a lua failure
function fw.fatal_fail(msg)
	logger:fatal("fatal_fail called with the following: " .. msg)
	ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- debug
function fw.finish(start)
	local finish = gettimeofday()
	logger:warn("Finished fw.exec in: " .. finish - start)
end


-- main entry point
-- data associated with a given request in kept local in scope to this function
-- because the lua api only loads this module once, so module-level variables
-- can be cross-polluted
function fw.exec(opts)
local start = gettimeofday()
logger:debug("Request started: " .. ngx.req.start_time())

if (type(opts) ~= "table") then
	fw.fatal_fail("opts is not a table, it is a " .. type(opts))
end

-- more sanity checks
local mode = opts.mode
if (mode == "INACTIVE") then
	logger:info("Operational mode is INACTIVE, not running")
	return
end

if (not fw.table_has_value(opts.mode, allowed_modes)) then
	fw.fatal_fail("Invalid operational mode provided: " .. tostring(mode))
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
local request_request_line = fw.get_request_line()

logger:debug("Comparing " .. request_client  .. " against whitelist")
if fw.table_has_value(request_client, opts.whitelist) then
	logger:info("Allowing " .. request_client .. " because of whitelist")
	ngx.exit(ngx.OK) -- exiting with OK passes to the next phase handler
end

logger:info("Handling a " .. request_method .. " request to " .. request_uri)

if (not fw.table_has_value(request_method, allowed_methods)) then
	if (mode == "ACTIVE") then 
		fw.rule_action("DENY") -- special case since this isn't a rule, but we should still follow the proper chain
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
local request_common_args = fw.build_common_args({ request_uri_args, request_post_args, request_cookies })

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
	HEADER_NAMES = fw.table_keys(request_headers),
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
		if (not fw.table_has_value(rule.id, ignored_rules)) then
			logger:debug("Beginning run of rule " .. rule.id)
			_process_rule(rule, collections, ctx)
		else
			logger:info("Ignoring rule " .. rule.id)
		end
	end
end

fw.finish(start)

end -- fw.exec()

function _process_rule(rule, collections, ctx)
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
	local t, specific = fw.parse_collection(collections[var.type], var.opts)

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

			local match_type = var.operator
			local match_pattern = var.pattern
			local match_collection = tostring(var.type) .. tostring(specific)

			if (not opts.nolog) then
				fw.log_event(user_id, request_client, request_uri, rule.id, match, match_type, match_pattern, match_collection)
			else
				logger:info("We had a match, but not logging because opts.nolog is set")
			end

			if (ctx.mode == "ACTIVE") then
				fw.rule_action(action, ctx.start)
			end
		end
	end

	if (opts.chainend == true) then
		ctx.chained = false
	end
end

function fw.log_event(user, request_client, request_uri, rule_id, match, match_type, match_pattern, match_collection)
	local t = {
		user_id = user,
		timestamp = ngx.time(),
		host = ngx.var.host,
		client = request_client,
		uri = request_uri,
		rule_id = rule_id,
		data = match,
		type = match_type,
		rule_pattern = match_pattern,
		collection = match_collection
	}

	logger:warn("EVENT LOGGED! " .. rule_id)
end

return fw
