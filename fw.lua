local fw = {}

local cookiejar = require "resty.cookie"
local cjson = require "cjson"

-- eventually this goes away in the name of performance
require("logging.file")
local logger = logging.file('/var/log/freewaf/fw.log')
logger:setLevel(logging.WARN)

-- logs to /fw/shm/sock/event_listener.sock
local event_logger = require "resty.logger.socket"

-- module-level table to define rule operators
-- no need to recreated this with every request
local operators = {
	REGEX = function(tables, pattern, opts) return fw.regex_match(tables, pattern, opts) end,
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
	DENY = function()
		logger:debug("rule.action was DENY, so telling nginx to quit!")
		fw.finish()
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
	logger:debug("Comparing " .. tostring(a) .. " and " .. tostring(b))

	_a = a
	_b = b

	if (type(_a) == "table") then
		logger:warn("We were passed a table for comparison, taking the first value instead (" ..tostring(a[1]) .. ")")
		_a = a[1]
	end	

	if (type(_a) ~= type(_b)) then
		fw.fatal_fail(type(_a) .. " " .. tostring(_a) .. " is not the same type as " .. type(b) .. " " .. tostring(b))
	end
	return _a == _b
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

-- upper-case the first letter of every word
function fw.normalize(s)
	return s:gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
end

-- properly case the HEADER_NAMES collection
function fw.normalize_header_names(headers)
	local header_names = fw.table_keys(headers)
	local new_headers = {}
	local n = 0

	for _, header in ipairs(header_names) do
		n = n + 1
		new_headers[n] = fw.normalize(header)
		logger:debug("header is now " .. new_headers[n])
	end

	return new_headers
end

-- regex matcher (uses POSIX patterns via ngx.re.match)
-- data is a table of strings
function fw.regex_match(table, pattern, opts)
	if (type(table) ~= "table") then
		logger:warn("regex_match received a " .. type(table) .. " for its target table when it should have been a table!") -- was previously fw.fatal_fail
		table = { tostring(table) } -- we probably got a string
	end
	if (type(pattern) ~= "string") then
		fw.fatal_fail("regex_match received a " .. type(pattern) .. " for its pattern when it should have been a string!")
	end

	-- by default we'll be case insensitive
	-- need to look over PCRE opts
	opts = opts or "oij"

	for i, value in ipairs(table) do
		logger:debug("matching " .. value .. " against " .. pattern)
		local from, to, err = ngx.re.find(value, pattern, opts)
		if err then logger:error("error in waf.regexmatch: " .. err) end
		if from then
			logger:debug("match! " .. string.sub(value, from, to))
			return string.sub(value, from, to)
		end
	end
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
function fw.rule_action(action)
	logger:info("Taking the following action: " .. action)
	local _ = actions[action]()
end

-- if we need to bail, 503 is distinguishable from the 500 that gets thrown from a lua failure
function fw.fatal_fail(msg)
	logger:fatal("fatal_fail called with the following: " .. msg)
	ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- debug
function fw.finish()
	ngx.update_time()
	logger:debug("Finished at " .. ngx.now())
	logger:warn("Finished fw.exec in: " .. ngx.now() - ngx.req.start_time())
end

-- setup the socket logger
function fw.init_logger()
	if not event_logger.initted() then
    	local ok, err = event_logger.init{
			host = '127.0.0.1',
			port = '7000',
			flush_limit = 32768,
			drop_limit = 1048576,
	    }   
    	if not ok then
        	fw.fatail_fail("failed to initialize the logger: ", err)
	        return
		end
		logger:debug("Initializing logger")
		fw.event_logger_timer()
	end
end

function fw.do_flush(premature)
	if premature then return end
	if event_logger.initted() then
		logger:debug("Flushing log via timer")
		event_logger.flush()
	end
	fw.event_logger_timer()
end

function fw.event_logger_timer()
	local ok, err = ngx.timer.at(15, fw.do_flush)
	if not ok then ngx.log(ngx.ERR, "failed to create timer for flushing logs: ", err) end
end


-- main entry point
-- data associated with a given request in kept local in scope to this function
-- because the lua api only loads this module once, so module-level variables
-- can be cross-polluted
function fw.exec(opts)
logger:debug("Request started: " .. ngx.req.start_time())
ngx.update_time()
logger:debug("Beginning fw.exec: " .. ngx.now())

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

fw.init_logger()

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
	HEADER_NAMES = fw.normalize_header_names(request_headers),
	USER_AGENT = request_ua,
	REQUEST_LINE = request_request_line,
	COOKIES = request_cookies,
	REQUEST_BODY = request_post_args,
	REQUEST_ARGS = request_common_args
}

for _, ruleset in ipairs(active_rulesets) do
	logger:info("Beginning ruleset " .. ruleset)
	
	logger:debug("Requiring rs_" .. ruleset)
	local rs = require("fw_rules.rs_" .. ruleset)

	for __, rule in ipairs(rs.rules()) do
		logger:info("Beginning run of rule " .. rule.id)
		if (type(rule.id) == "string") then
			rule.id = tonumber(rule.id) -- i'm lazy
		end
		if (fw.table_has_value(rule.id, ignored_rules)) then
			logger:info("Ignoring rule " .. rule.id)
			break
		end

		local match
		local match_type
		local match_pattern
		local match_collection
		local matchcount = 0

		logger:debug("We will need " .. #rule.vars .. " matches")
		for ___, var in ipairs(rule.vars) do

			-- fucking hack
			if (type(var.type) == "string") then
				logger:warn("var.type " .. var.type .. " is a string, so building a table out of it")
				var.type = { var.type }
			end

			for i, _var in ipairs(var.type) do
				logger:debug("Parsing the collection " .. var.type[i])
				local t, specific = fw.parse_collection(collections[var.type[i]], var.opts[i])

				if (t == nil) then
					logger:info("Collection " .. tostring(var.type[i]) .. " was not found or was nil after applying " .. tostring(var.opts[i].specific))
				else
					logger:debug("Matching with the following operator: " .. var.operator)
					match = operators[var.operator](t, var.pattern)
					if (match) then 
						match_type = var.operator
						match_pattern = var.pattern
						match_collection = tostring(var.type[i]) .. tostring(specific)
						matchcount = matchcount + 1
						break -- if we have a match from this var, we probably dont need to keep going
					end
				end
				logger:debug("Matchcount is now " .. matchcount)
			end

			if (not match) then
				logger:info("Breaking because we didn't find a previous match, so no reason to keep going")
				break
			end
		end

		if (matchcount >= #rule.vars) then
			logger:info("Matchcount was sufficient (" .. matchcount .. ") to trigger rule action " .. rule.action)
			if (rule.action ~= "IGNORE") then
				fw.log_event(user_id, request_client, request_uri, rule.id, match, match_type, match_pattern, match_collection)
			end

			if (mode == "ACTIVE") then
				fw.rule_action(rule.action)
			end
		else
			logger:info("Matchcount of " .. matchcount .. " was insufficient to trigger action")
		end

		logger:info("Run of rule " .. rule.id .. " finished")
	end
end

fw.finish()

end -- fw.exec()

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

	event_logger.log(cjson.encode(t) .. "\n")
end

return fw
