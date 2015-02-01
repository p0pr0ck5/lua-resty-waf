local _M = {}

_M.version = "0.3"

local ac = require("inc.load_ac")
local cjson = require("cjson")
local cookiejar = require("inc.resty.cookie")
local file_logger = require("inc.resty.logger.file")
local socket_logger = require("inc.resty.logger.socket")

local mt = { __index = _M }

-- module-level cache of aho-corasick dictionary objects
local _ac_dicts = {}

local function _log(self, msg)
	if (self._debug == true) then
		ngx.log(self._debug_log_level, msg)
	end
end

local function _fatal_fail(msg)
	ngx.log(ngx.ERR, "_fatal_fail called with the following: " .. msg)
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- used for operators.EQUALS
local function _equals(self, a, b)
	local equals
	if (type(a) == "table") then
		_log(self, "Needle is a table, so recursing!")
		for _, v in ipairs(a) do
			equals = _equals(self, v, b)
			if (equals) then
				break
			end
		end
	else
		_log(self, "Comparing " .. tostring(a) .. " and " .. tostring(b))
		equals = a == b
	end

	return equals
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
local function _table_copy(self, orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_table_copy(orig_key)] = _table_copy(self, orig_value)
        end
        setmetatable(copy, _table_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- return a table containing the keys of the provided table
local function _table_keys(self, table)
	local t = {}
	local n = 0

	for key, _ in pairs(table) do
		n = n + 1
		t[n] = tostring(key) -- tostring is probably too large a hammer
	end

	return t
end

-- return a table containing the values of the provided table
local function _table_values(self, table)
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
local function _table_has_key(self, needle, haystack)
	if (type(haystack) ~= "table") then
		_fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end
	_log(self, "table key " .. needle .. " is " .. tostring(haystack[needle]))
	return haystack[needle] ~= nil
end

-- determine if the haystack table has a needle for a key
local function _table_has_value(self, needle, haystack)
	_log(self, "Searching for " .. needle)

	if (type(haystack) ~= "table") then
		_fatal_fail("Cannot search for a needle when haystack is type " .. type(haystack))
	end

	for _, value in pairs(haystack) do
		_log(self, "Checking " .. value)
		if (value == needle) then return true end
	end
end

-- regex matcher (uses POSIX patterns via ngx.re.match)
local function _regex_match(self, subject, pattern, opts)
	local opts = "oij"
	local from, to, err
	local match

	if (type(subject) == "table") then
		_log(self, "subject is a table, so recursing!")
		for _, v in ipairs(subject) do
			match = _regex_match(self, v, pattern, opts)
			if (match) then
				break
			end
		end
	else
		_log(self, "matching " .. subject .. " against " .. pattern)
		from, to, err = ngx.re.find(subject, pattern, opts)
		if err then ngx.log(ngx.WARN, "error in waf.regexmatch: " .. err) end
		if from then
			_log(self, "regex match! " .. string.sub(subject, from, to))
			match = string.sub(subject, from, to)
		end
	end

	return match
end

-- efficient string search operator
-- uses CF implementation of aho-corasick-lua
local function _ac_lookup(self, needle, haystack, ctx)
	local id = ctx.id
	local match, _ac

	-- dictionary creation is expensive, so we use the id of
	-- the rule as the key to cache the created dictionary 
	if (not _ac_dicts[id]) then
		_log(self, "AC dict not found, calling libac.so")
		_ac = ac.create_ac(haystack)
		_ac_dicts[id] = _ac
	else
		_log(self, "AC dict found, pulling from the module cache")
		_ac = _ac_dicts[id]
	end

	if (type(needle) == "table") then
		_log(self, "needle is a table, so recursing!")
		for _, v in ipairs(needle) do
			match = _ac_lookup(self, v, haystack, ctx)
			if (match) then
				break
			end
		end
	else
		match = ac.match(_ac, needle)
	end

	return match
end

local function _parse_collection(self, collection, opts)
	local lookup = {
		specific = function(self, collection, value)
			_log(self, "_parse_collection is getting a specific value: " .. value)
			return collection[value]
		end,
		ignore = function(self, collection, value)
			_log(self, "_parse_collection is ignoring a value: " .. value)
			local _collection = {}
			_collection = _table_copy(self, collection)
			_collection[value] = nil
			return _collection
		end,
		keys = function(self, collection)
			_log(self, "_parse_collection is getting the keys")
			return _table_keys(self, collection)
		end,
		values = function(self, collection)
			_log(self, "_parse_collection is getting the values")
			return _table_values(self, collection)
		end,
		all = function(self, collection)
			local n = 0
			local _collection = {}
			for _, key in ipairs(_table_keys(self, collection)) do
				n = n + 1
				_collection[n] = key
			end
			for _, value in ipairs(_table_values(self, collection)) do
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

	return lookup[opts.key](self, collection, opts.value)
end

local function _build_common_args(self, collections)
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
				_log(self, "t[" .. k .. "] contains " .. tostring(t[k]))
			end
		end
	end

	return t
end

local function _log_event(self, request_client, request_uri, rule, match)
	local t = {
		client = request_client,
		uri = request_uri,
		match = match,
		rule = { id = rule.id }
	}

	if (self._event_log_verbosity > 1) then
		t.rule.description = rule.description
	end

	if (self._event_log_verbosity > 2) then
		t.rule.opts = rule.opts
		t.rule.action = rule.action
	end

	if (self._event_log_verbosity > 3) then
		t.rule.var = rule.var
	end

	local lookup = {
		error = function(t)
			ngx.log(self._event_log_level, cjson.encode(t))
		end,
		file = function(t)
			if (not file_logger.initted()) then
				file_logger.init{
					path = self._event_log_target_path,
					flush_limit = self.event_log_buffer_size
				}
			end

			file_logger.log(t)
		end,
		socket = function(t)
			if (not socket_logger.initted()) then
				socket_logger.init{
					host = self._event_log_target_host,
					port = self._event_log_target_path,
					flush_limit = self.event_log_buffer_size
				}
			end

			socket_logger.log(t)
		end
	}

	lookup[self._event_log_target](cjson.encode(t) .. "\n")
end

-- module-level table to define rule operators
-- no need to recreated this with every request
local operators = {
	REGEX = function(self, subject, pattern, opts) return _regex_match(self, subject, pattern, opts) end,
	NOT_REGEX = function(self, subject, pattern, opts) return not _regex_match(self, subject, pattern, opts) end,
	EQUALS = function(self, a, b) return _equals(self, a, b) end,
	NOT_EQUALS = function(self, a, b) return not _equals(self, a, b) end,
	EXISTS = function(self, haystack, needle) return _table_has_value(self, needle, haystack) end,
	NOT_EXISTS = function(self, haystack, needle) return not _table_has_value(self, needle, haystack) end,
	PM = function(self, needle, haystack, ctx) return _ac_lookup(self, needle, haystack, ctx) end,
	NOT_PM = function(self, needle, haystack, ctx) return not _ac_lookup(self, needle, haystack, ctx) end
}

-- use the lookup table to figure out what to do
local function _rule_action(self, action, ctx)
	local actions = {
		LOG = function(self)
			_log(self, "rule.action was LOG, since we already called log_event this is relatively meaningless")
		end,
		ACCEPT = function(self, ctx)
			_log(self, "An explicit ACCEPT was sent, so ending this phase with ngx.OK")
			if (self._mode == "ACTIVE") then
				ngx.exit(ngx.OK)
			end
		end,
		CHAIN = function(self, ctx)
			_log(self, "Setting the context chained flag to true")
			ctx.chained = true
		end,
		SKIP = function(self, ctx)
			_log(self, "Setting the context skip flag to true")
			ctx.skip = true
		end,
		SCORE = function(self, ctx)
			local new_score = ctx.score + ctx.rule_score
			_log(self, "New score is " .. new_score)
			ctx.score = new_score
		end,
		DENY = function(self, ctx)
			_log(self, "rule.action was DENY, so telling nginx to quit!")
			if (self._mode == "ACTIVE") then
				ngx.exit(ngx.HTTP_FORBIDDEN)
			end
		end,
		IGNORE = function(self)
			_log(self, "Ingoring rule for now")
		end
	}

	_log(self, "Taking the following action: " .. action)
	actions[action](self, ctx)
end

-- build the transform portion of the collection memoization key
local function _transform_memokey(transform)
	if (not transform) then
		return 'nil'
	end

	if (type(transform) ~= 'table') then
		return tostring(transform)
	else
		return table.concat(transform, ',')
	end
end

-- transform collection values based on rule opts
local function _do_transform(self, collection, transform)
	local lookup = {
		base64_decode = function(self, value)
			_log(self, "Decoding from base64: " .. tostring(value))
			local t_val = ngx.decode_base64(tostring(value))
			if (t_val) then
				_log(self, "decode successful, decoded value is " .. t_val)
				return t_val
			else
				_log(self, "decode unsuccessful, returning original value " .. value)
				return value
			end
		end,
		base64_encode = function(self, value)
			_log(self, "Encoding to base64: " .. tostring(value))
			local t_val = ngx.encode_base64(value)
			_log(self, "encoded value is " .. t_val)
		end,
		html_decode = function(self, value)
			local str = string.gsub(value, '&lt;', '<')
			str = string.gsub(str, '&gt;', '>')
			str = string.gsub(str, '&quot;', '"')
			str = string.gsub(str, '&apos;', "'")
			str = string.gsub(str, '&#(%d+);', function(n) return string.char(n) end)
			str = string.gsub(str, '&#x(%d+);', function(n) return string.char(tonumber(n,16)) end)
			str = string.gsub(str, '&amp;', '&')
			_log(self, "html decoded value is " .. str)
			return str
		end,
		lowercase = function(self, value)
			return string.lower(tostring(value))
		end
	}

	-- create a new tmp table to hold the transformed values
	local t = {}

	if (type(transform) == "table") then
		_log(self, "multiple transforms are defined, iterating through each one")
		t = collection
		for k, v in ipairs(transform) do
			t = _do_transform(self, t, transform[k])
		end
	else
		-- if the collection is a table, loop through it and add the values to the tmp table
		-- otherwise, this returns directly to _process_rule or a recursed call from multiple transforms
		if (type(collection) == "table") then
			_log(self, "collection is a table, recursing its transform for each element")
			for k, v in pairs(collection) do
				t[k] = _do_transform(self, collection[k], transform)
			end
		else
			if (not collection) then
				return collection -- dont transform if the collection was nil, i.e. a specific arg key dne
			end

			_log(self, "doing transform of type " .. transform .. " on collection value " .. tostring(collection))
			return lookup[transform](self, collection)
		end
	end

	return t
end

local function _process_rule(self, rule, collections, ctx)
	local id = rule.id
	local var = rule.var
	local opts = rule.opts
	local action = rule.action
	local description = rule.description

	ctx.id = id
	ctx.rule_score = opts.score

	if (opts.chainchild == true and ctx.chained == false) then
		_log(self, "This is a chained rule, but we don't have a previous match, so not processing")
		return
	end

	if (ctx.skip == true) then
		_log(self, "Skipflag is set, not processing")
		if (opts.skipend == true) then
			_log(self, "End of the skipchain, unsetting flag")
			ctx.skip = false
		end
		return
	end

	local t
	local memokey
	if (var.opts ~= nil) then
		_log(self, "var opts is not nil")
		memokey = var.type .. tostring(var.opts.key) .. tostring(var.opts.value) .. _transform_memokey(opts.transform)
	else
		_log(self, "var opts is nil, memo cache key is only the var type")
		memokey = var.type
	end

	_log(self, "checking for memokey " .. memokey)

	if (not ctx.collections_key[memokey]) then
		_log(self, "parsing collections for rule " .. id)
		t = _parse_collection(self, collections[var.type], var.opts)
		if (opts.transform) then
			t = _do_transform(self, t, opts.transform)
		end
		ctx.collections[memokey] = t
		ctx.collections_key[memokey] = true
	else
		_log(self, "parse collection cache hit!")
		t = ctx.collections[memokey]
	end

	if (not t) then
		_log(self, "parse_collection didnt return anything for " .. var.type)
	else
		local match = operators[var.operator](self, t, var.pattern, ctx)
		if (match) then
			_log(self, "Match of rule " .. id .. "!")

			if (not opts.nolog) then
				_log_event(self, collections["CLIENT"], collections["URI"], rule, match)
			else
				_log(self, "We had a match, but not logging because opts.nolog is set")
			end

			_rule_action(self, action, ctx)
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
function _M.exec(self)
	if (self._mode == "INACTIVE") then
		_log(self, "Operational mode is INACTIVE, not running")
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
	local request_post_args

	if (_table_has_key(self, request_client, self._whitelist)) then
		_log(self, request_client .. " is whitelisted")
		ngx.exit(ngx.OK)
	end

	if (_table_has_key(self, request_client, self._blacklist)) then
		_log(self, request_client .. " is blacklisted")
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
			_log(self, "Skipping POST arguments because we buffered to disk")
		end
	end

	local cookies = cookiejar:new() -- resty.cookie
	local request_cookies, cookie_err = cookies:get_all()
	local request_common_args = _build_common_args(self, { request_uri_args, request_post_args, request_cookies })

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
		HEADER_NAMES = _table_keys(self, request_headers),
		USER_AGENT = request_ua,
		REQUEST_LINE = request_request_line,
		COOKIES = request_cookies,
		REQUEST_BODY = request_post_args,
		REQUEST_ARGS = request_common_args
	}

	local ctx = {}
	ctx.start = start
	ctx.collections = {}
	ctx.collections_key = {}
	ctx.chained = false
	ctx.skip = false
	ctx.score = 0

	for _, ruleset in ipairs(self._active_rulesets) do
		_log(self, "Beginning ruleset " .. ruleset)

		_log(self, "Requiring " .. ruleset)
		local rs = require("FreeWAF.rules." .. ruleset)

		for __, rule in ipairs(rs.rules()) do
			if (not _table_has_key(self, rule.id, self._ignored_rules)) then
				_log(self, "Beginning run of rule " .. rule.id)
				_process_rule(self, rule, collections, ctx)
			else
				_log(self, "Ignoring rule " .. rule.id)
			end
		end
	end

	-- if we've made it this far, we haven't
	-- explicitly DENY'd or ACCEPT'd the request,
	-- so see if the score meets our threshold
	if (ctx.score >= self._score_threshold) then
		-- should we provide a threshold breach rule action, instead of defaulting to DENY?
		_log(self, "Transaction score of " .. ctx.score .. " met our threshold limit!")
		_rule_action(self, "DENY", ctx)
	end

end -- fw.exec()

function _M.new(self)
	return setmetatable({
		_mode = "SIMULATE",
		_whitelist = {},
		_blacklist = {},
		_active_rulesets = { 20000, 21000, 35000, 40000, 41000, 42000, 90000 },
		_ignored_rules = {},
		_debug = false,
		_debug_log_level = ngx.INFO,
		_event_log_level = ngx.INFO,
		_event_log_verbosity = 1,
		_event_log_target = 'error',
		_event_log_target_host = '',
		_event_log_target_port = '',
		_event_log_target_path = '',
		_event_log_buffer_size = 4096,
		_score_threshold = 5,
	}, mt)
end

function _M.set_option(self, option, value)
	local lookup = {
		mode = function(value)
			self._mode = value
		end,
		whitelist = function(value)
			self._whitelist[value] = true
		end,
		blacklist = function(value)
			self._blacklist[value] = true
		end,
		ignore_ruleset = function(value)
			local t = {}
			local n = 1
			for k, v in ipairs(self._active_rulesets) do
				if (v ~= value) then
					t[n] = v
				end
				n = n + 1
			end
			self._active_rulesets = t
		end,
		ignore_rule = function(value)
			self._ignored_rules[value] = true
		end,
		debug = function(value)
			self._debug = value
		end,
		debug_log_level = function(value)
			self._debug_log_level = value
		end,
		event_log_level = function(value)
			self._event_log_level = value
		end,
		event_log_verbosity = function(value)
			self._event_log_verbosity = value
		end,
		event_log_target = function(value)
			self._event_log_target = value
		end,
		event_log_target_host = function(value)
			self._event_log_target_host = value
		end,
		event_log_target_port = function(value)
			self._event_log_target_port = value
		end,
		event_log_target_path = function(value)
			self._event_log_target_path = value
		end,
		event_log_buffer_size = function(value)
			self.event_log_buffer_size = value
		end,
		score_threshold = function(value)
			self._score_threshold = value
		end
	}

	if (type(value) == "table") then
		for _, v in ipairs(value) do
			_M:set_option(option, v)
		end
	else
		lookup[option](value)
	end

end

return _M
