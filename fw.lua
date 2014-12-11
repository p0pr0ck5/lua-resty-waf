local _M = {}

_M.version = "0.1"

local ac = require("inc.load_ac")
local cjson = require("cjson")
local cookiejar = require("inc.resty.cookie")
local ffi = require("ffi")

-- cached aho-corasick dictionary objects
local _ac_dicts

-- module-level options
local _mode, _whitelist, _blacklist, _active_rulesets, _ignored_rules, _debug, _score_threshold

local function _log(msg)
	if (_debug == true) then
		ngx.log(ngx.DEBUG, msg)
	end
end

-- used for operators.EQUALS
local function _equals(a, b)
	local equals
	if (type(a) == "table") then
		_log("Needle is a table, so recursing!")
		for _, v in ipairs(a) do
			equals = _equals(v, b)
			if (equals) then
				break
			end
		end
	else
		_log("Comparing " .. a .. " and " .. b)
		equals = a == b
	end

	return equals
end

-- used for operators.NOT_EQUALS
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
	_log("table key " .. needle .. " is " .. tostring(haystack[needle]))
	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
local function _table_has_value(needle, haystack)
	_log("Searching for " .. needle)

	if (type(haystack) ~= "table") then
		_fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		_log("Checking " .. value)
		if (value == needle) then return true end
	end
end

-- inverse of fw.table_has_value
local function _table_not_has_value(needle, value)
	return not _table_has_value(needle, value)
end

-- regex matcher (uses POSIX patterns via ngx.re.match)
local function _regex_match(subject, pattern, opts)
	local opts = "oij"
	local from, to, err
	local match

	if (type(subject) == "table") then
		_log("subject is a table, so recursing!")
		for _, v in ipairs(subject) do
			match = _regex_match(v, pattern, opts)
			if (match) then
				break
			end
		end
	else
		_log("matching " .. subject .. " against " .. pattern)
		from, to, err = ngx.re.find(subject, pattern, opts)
		if err then ngx.log(ngx.WARN, "error in waf.regexmatch: " .. err) end
		if from then
			_log("regex match! " .. string.sub(subject, from, to))
			match = string.sub(subject, from, to)
		end
	end

	return match
end

-- efficient string search operator
-- uses CF implementation of aho-corasick-lua
local function _ac_lookup(needle, haystack, ctx)
	local id = ctx.id
	local match, _ac

	if (not _ac_dicts[id]) then
		_log("AC dict not found, calling libac.so")
		_ac = ac.create_ac(haystack)
		_ac_dicts[id] = _ac
	else
		_log("AC dict found, pulling from the module cache")
		_ac = _ac_dicts[id]
	end

	if (type(needle) == "table") then
		_log("needle is a table, so recursing!")
		for _, v in ipairs(needle) do
			match = _ac_lookup(v, haystack, ctx)
			if (match) then
				break
			end
		end
	else
		match = ac.match(_ac, needle)
	end

	return match
end

local function _parse_collection(collection, opts)
	local lookup = {
		specific = function(collection, value)
			_log("_parse_collection is getting a specific value: " .. value)
			return collection[value]
		end,
		ignore = function(collection, value)
			_log("_parse_collection is ignoring a value: " .. value)
			local _collection = {}
			_collection = _table_copy(collection)
			_collection[value] = nil
			return _collection
		end,
		keys = function(collection)
			_log("_parse_collection is getting the keys")
			return _table_keys(collection)
		end,
		values = function(collection)
			_log("_parse_collection is getting the values")
			return _table_values(collection)
		end,
		all = function(collection)
			local n = 0
			local _collection = {}
			for _, key in ipairs(_table_keys(collection)) do
				n = n + 1
				_collection[n] = key
			end
			for _, value in ipairs(_table_values(collection)) do
				n = n + 1
				_collection[n] = value
			end
			return _collection
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
				_log("t[" .. k .. "] contains " .. tostring(t[k]))
			end
		end
	end

	return t
end

local function _fatal_fail(msg)
	ngx.log(ngx.ERR, "_fatal_fail called with the following: " .. msg)
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local function _log_event(request_client, request_uri, rule, match)
	local t = {
		client = request_client,
		uri = request_uri,
		rule = rule,
		match = match
	}

	ngx.log(ngx.INFO, cjson.encode(t))
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
	PM = function(needle, haystack, ctx) return _ac_lookup(needle, haystack, ctx) end,
	NOT_PM = function(needle, haystack, ctx) return not _ac_lookup(needle, haystack, ctx) end
}

-- module-level table to define rule actions
-- this may get changed if/when heuristics gets introduced
local actions = {
	LOG = function()
		_log("rule.action was LOG, since we already called log_event this is relatively meaningless")
	end,
	ACCEPT = function(ctx)
		_log("An explicit ACCEPT was sent, so ending this phase with ngx.OK")
		if (ctx.mode == "ACTIVE") then
			ngx.exit(ngx.OK)
		end
	end,
	CHAIN = function(ctx)
		_log("Setting the context chained flag to true")
		ctx.chained = true
	end,
	SKIP = function(ctx)
		_log("Setting the context skip flag to true")
		ctx.skip = true
	end,
	SKIPRS = function(ctx)
		_log("Setting the skip ruleset flag")
		ctx.skiprs = true
	end,
	SCORE = function(ctx)
		local new_score = ctx.score + ctx.rule_score
		_log("New score is " .. new_score)
		ctx.score = new_score
	end,
	DENY = function(ctx)
		_log("rule.action was DENY, so telling nginx to quit!")
		if (ctx.mode == "ACTIVE") then
			ngx.exit(ngx.HTTP_FORBIDDEN)
		end
	end,
	IGNORE = function()
		_log("Ingoring rule for now")
	end
}

-- use the lookup table to figure out what to do
local function _rule_action(action, start)
	_log("Taking the following action: " .. action)
	actions[action](start)
end

local function _process_rule(rule, collections, ctx)
	local id = rule.id
	local var = rule.var
	local opts = rule.opts
	local action = rule.action
	local description = rule.description

	ctx.id = id
	ctx.rule_score = opts.score

	if (opts.chainchild == true and ctx.chained == false) then
		_log("This is a chained rule, but we don't have a previous match, so not processing")
		return
	end

	if (ctx.skip == true) then
		_log("Skipflag is set, not processing")
		if (opts.skipend == true) then
			_log("End of the skipchain, unsetting flag")
			ctx.skip = false
		end
		return
	end

	local t
	local memokey
	if (var.opts ~= nil) then
		_log("var opts is not nil")
		memokey = var.type .. tostring(var.opts.key) .. tostring(var.opts.value)
	else
		_log("var opts is nil, memo cache key is only the var type")
		memokey = var.type
	end

	_log("checking for memokey " .. memokey)

	if (not ctx.collections_key[memokey]) then
		_log("parsing collections for rule " .. id)
		t = _parse_collection(collections[var.type], var.opts)
		ctx.collections[memokey] = t
		ctx.collections_key[memokey] = true
	else
		_log("parse collection cache hit!")
		t = ctx.collections[memokey]
	end

	if (not t) then
		_log("parse_collection didnt return anything for " .. var.type)
	else
		local match = operators[var.operator](t, var.pattern, ctx)
		if (match) then
			_log("Match of rule " .. id .. "!")

			if (not opts.nolog) then
				_log_event(request_client, request_uri, rule, match)
			else
				_log("We had a match, but not logging because opts.nolog is set")
			end

			_rule_action(action, ctx)
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
function _M.exec()
	if (_mode == "INACTIVE") then
		_log("Operational mode is INACTIVE, not running")
		return
	end

	local request_client = ngx.var.remote_addr
	local request_http_version = ngx.req.http_version()
	local request_method = ngx.req.get_method()
	local request_uri = ngx.var.uri
	local request_uri_args = ngx.req.get_uri_args()
	local request_headers = ngx.req.get_headers()
	local request_ua = ngx.var.http_user_agent
	local request_request_line = _get_request_line()

	if (_table_has_key(request_client, _whitelist)) then
		_log(request_client .. " is whitelisted")
		ngx.exit(ngx.OK)
	end

	if (_table_has_key(request_client, _blacklist)) then
		_log(request_client .. " is blacklisted")
		ngx.exit(ngx.HTTP_FORBIDDEN)
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
			ngx.log(ngxINFOO, "Skipping POST arguments because we buffered to disk")
		end
	end

	local cookies = cookiejar:new() -- resty.cookie
	local request_cookies, cookie_err = cookies:get_all()
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
	ctx.mode = _mode
	ctx.start = start
	ctx.collections = {}
	ctx.collections_key = {}
	ctx.chained = false
	ctx.skip = false
	ctx.skiprs = false
	ctx.score = 0

	for _, ruleset in ipairs(_active_rulesets) do
		_log("Beginning ruleset " .. ruleset)

		_log("Requiring " .. ruleset)
		local rs = require("FreeWAF.rules." .. ruleset)

		for __, rule in ipairs(rs.rules()) do
			if (ctx.skiprs == true) then
				_log("skiprs is set, so breaking!")
				ctx.skiprs = false
				break
			end

			if (not _table_has_key(rule.id, _ignored_rules)) then
				_log("Beginning run of rule " .. rule.id)
				_process_rule(rule, collections, ctx)
			else
				_log("Ignoring rule " .. rule.id)
			end
		end
	end

	-- if we've made it this far, we haven't
	-- explicitly DENY'd or ACCEPT'd the request,
	-- so see if the score meets our threshold
	if (ctx.score >= _score_threshold) then
		-- should we provide a threshold breach rule action, instead of defaulting to DENY?
		_log("Transaction score of " .. ctx.score .. " met our threshold limit!")
		_rule_action("DENY", ctx)
	end

end -- fw.exec()

function _M.init()
	_mode = "SIMULATE"
	_whitelist = {}
	_blacklist = {}
	_active_rulesets = { 20000, 21000, 35000, 40000, 41000, 42000, 90000 }
	_ignored_rules = {}
	_debug = false
	_score_threshold = 5

	_ac_dicts = {}
end

function _M.set_option(option, value)
	local lookup = {
		mode = function(value)
			_mode = value
		end,
		whitelist = function(value)
			_whitelist[value] = true
		end,
		blacklist = function(value)
			_blacklist[value] = true
		end,
		ignore_ruleset = function(value)
			_active_rulesets = value
		end,
		ignore_rule = function(value)
			_ignored_rules[value] = true
		end,
		debug = function(value)
			_debug = value
		end,
		score_threshold = function(value)
			_score_threshold = value
		end
	}

	if (type(value) == "table") then
		for _, v in ipairs(value) do
			_M.set_option(option, v)
		end
	else
		lookup[option](value)
	end

end

return _M
