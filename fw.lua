local _M = {}

_M.version = "0.5.2"

local ac = require("inc.load_ac")
local cjson = require("cjson")
local cookiejar = require("inc.resty.cookie")
local file_logger = require("inc.resty.logger.file")
local socket_logger = require("inc.resty.logger.socket")
local upload = require("inc.resty.upload")

local mt = { __index = _M }

-- module-level cache of aho-corasick dictionary objects
local _ac_dicts = {}

-- default list of rulesets (global here to have offsets precomputed)
_global_active_rulesets = { 10000, 11000, 20000, 21000, 35000, 40000, 41000, 42000, 90000, 99000 }

-- debug logger
local function _log(self, msg)
	if (self._debug == true) then
		ngx.log(self._debug_log_level, msg)
	end
end

-- fatal failure logger
local function _fatal_fail(msg)
	ngx.log(ngx.ERR, error(msg))
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

-- used for operators.GREATER
local function _greater(self, a, b)
	local greater
	if (type(a) == "table") then
		_log(self, "Needle is a table, so recursing!")
		for _, v in ipairs(a) do
			greater = _greater(self, v, b)
			if (greater) then
				break
			end
		end
	else
		_log(self, "Comparing (greater) " .. tostring(a) .. " and " .. tostring(b))
		greater = a > b
	end

	return greater
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

-- regex matcher (uses PCRE patterns via ngx.re.match)
local function _regex_match(self, subject, pattern)
	local opts = self._pcre_flags
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

-- get a subset or superset of request data collection
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

-- return a single table from multiple tables containing request data
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

-- buffer a single log event into the per-request ctx table
-- all event logs will be written out at the completion of the transaction if either:
-- 1. the transaction was altered (e.g. a rule matched with an ACCEPT or DENY action), or
-- 2. the event_log_altered_only option is unset
local function _log_event(self, request_client, request_uri, rule, match, ctx)
	local t = {
		timestamp = ngx.time(),
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

	ctx.log_entries[#ctx.log_entries + 1] = t
end

-- push log data regarding matching rule(s) to the configured target
-- in the case of socket or file logging, this data will be buffered
local function _write_log_events(self, ctx)
	local lookup = {
		error = function(t)
			ngx.log(self._event_log_level, cjson.encode(t))
		end,
		file = function(t)
			if (not file_logger.initted()) then
				file_logger.init{
					path = self._event_log_target_path,
					flush_limit = self._event_log_buffer_size,
					periodic_flush = self._event_log_periodic_flush
				}
			end

			file_logger.log(cjson.encode(t) .. "\n")
		end,
		socket = function(t)
			if (not socket_logger.initted()) then
				socket_logger.init{
					host = self._event_log_target_host,
					port = self._event_log_target_port,
					flush_limit = self._event_log_buffer_size,
					period_flush = self._event_log_periodic_flush
				}
			end

			socket_logger.log(cjson.encode(t) .. "\n")
		end
	}

	if (not ctx.altered and self._event_log_altered_only) then
		_log(self, "Not logging a request that wasn't altered")
		return
	end

	for _, entry in ipairs(ctx.log_entries) do
		lookup[self._event_log_target](entry)
	end

	-- clear log entries so we don't write duplicates
	ctx.log_entries = {}
end

-- cleanup
local function _finalize(self, ctx)
	-- write out any log events from this transaction
	_write_log_events(self, ctx)
end

-- module-level table to define rule operators
-- no need to recreate this with every request
local operators = {
	REGEX = function(self, subject, pattern, opts) return _regex_match(self, subject, pattern, opts) end,
	NOT_REGEX = function(self, subject, pattern, opts) return not _regex_match(self, subject, pattern, opts) end,
	EQUALS = function(self, a, b) return _equals(self, a, b) end,
	NOT_EQUALS = function(self, a, b) return not _equals(self, a, b) end,
	GREATER = function(self, a, b) return _greater(self, a, b) end,
	NOT_GREATER = function(self, a, b) return not _greater(self, a, b) end,
	EXISTS = function(self, haystack, needle) return _table_has_value(self, needle, haystack) end,
	NOT_EXISTS = function(self, haystack, needle) return not _table_has_value(self, needle, haystack) end,
	PM = function(self, needle, haystack, ctx) return _ac_lookup(self, needle, haystack, ctx) end,
	NOT_PM = function(self, needle, haystack, ctx) return not _ac_lookup(self, needle, haystack, ctx) end
}

-- pick out dynamic data from storage key definitions
local function _parse_dynamic_value(self, key, collections)
	local lookup = function(m)
		local val = collections[m[1]]

		if (not val) then
			_fatal_fail("Bad dynamic parse, no collection key " .. m[1])
		end

		if (type(val) == "table") then
			return m[1]
		elseif (type(val) == "function") then
			return val(self)
		else
			return val
		end
	end

	-- use a negated character (instead of a lazy regex) to grab something that looks like
	-- %{VAL}
	-- and find it in the lookup table
	local str = ngx.re.gsub(key, [=[%{([^{]*)}]=], lookup, 'oij')
	_log(self, "parsed dynamic value is " .. str)
	if (ngx.re.find(str, [=[^\d+$]=], self._pcre_flags)) then
		return tonumber(str)
	else
		return str
	end
end

-- retrieve a given key from persistent storage
local function _retrieve_persistent_var(self, key)
	local shm = ngx.shared[self._storage_zone]
	local var = shm:get(key)
	return var
end

-- wrapper to get persistent storage data
local function _get_var(self, key, collections)
	-- silently bail from rules that require persistent storage if no shm was configured
	if (not self._storage_zone) then
		return
	end

	return _retrieve_persistent_var(self, _parse_dynamic_value(self, key, collections))
end

-- add/update data to persistent storaage
local function _set_var(self, ctx, collections)
	-- silently bail from rules that require persistent storage if no shm was configured
	if (not self._storage_zone) then
		return
	end

	local key = _parse_dynamic_value(self, ctx.rule_setvar_key, collections)
	local value = _parse_dynamic_value(self, ctx.rule_setvar_value, collections)
	local expire = ctx.rule_setvar_expire or 0
	_log(self, "initially setting " .. ctx.rule_setvar_key .. " to " .. ctx.rule_setvar_value)
	local shm = ngx.shared[self._storage_zone]

	-- values can have arithmetic operations performed on them
	local incr = ngx.re.match(value, [=[^([\+\-\*\/])(\d+)]=], self._pcre_flags)
	if (incr) then
		local operator = incr[1]
		local newval = incr[2]
		local oldval = _retrieve_persistent_var(self, key)
		if (not oldval) then
			oldval = 0
		end

		if (operator == "+") then
			value = oldval + newval
		elseif (operator == "-") then
			value = oldval - newval
		elseif (operator == "*") then
			value = oldval * newval
		elseif (operator == "/") then
			value = oldval / newval
		end
	end

	_log(self, "actually setting " .. key .. " to " .. value)

	_log(self, "expiring in " .. expire)
	local ok = shm:safe_set(key, value, expire)
	if (not ok) then
		ngx.log(ngx.WARN, "Could not add key to persistent storage, increase the size of the lua_shared_dict " .. self._storage_zone)
	end
end

local _alter_actions = { "ACCEPT", "DENY" }

-- use the lookup table to figure out what to do
local function _rule_action(self, action, ctx, collections)
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
			_log(self, "Chaining (pre-processed)")
		end,
		SKIP = function(self, ctx)
			_log(self, "Skipping (pre-processed)")
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
		end,
		SETVAR = function(self, ctx)
			_set_var(self, ctx, collections)
		end
	}

	if (_table_has_value(self, action, _alter_actions)) then
		ctx.altered = true
		_finalize(self, ctx)
	end

	_log(self, "Taking the following action: " .. action)
	actions[action](self, ctx, collections)
end

-- handle request bodies
local function _parse_request_body(self, request_headers)
	local content_type_header = request_headers["content-type"]

	-- multiple content-type headers are likely an evasion tactic
	-- or result from misconfigured proxies. may consider relaxing
	-- this or adding an option to disable this checking in the future
	if (type(content_type_header) == "table") then
		_log(self, "request contained multiple content-type headers, bailing!")
		ngx.exit(400)
	end

	-- ignore the request body if no Content-Type header is sent
	-- this does technically violate the RFC
	-- but its necessary for us to properly handle the request
	-- and its likely a sign of nogoodnickery anyway
	if (not content_type_header) then
		_log(self, "request has no content type, ignoring the body")
		ngx.req.discard_body()
		return
	end

	-- handle the request body based on the Content-Type header
	-- multipart/form-data requests will be streamed in via lua-resty-upload,
	-- which provides some basic sanity checking as far as form and protocol goes
	-- (but its much less strict that ModSecurity's strict checking)
	if (ngx.re.find(content_type_header, [=[^multipart/form-data; boundary=]=], self._pcre_flags)) then
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
				_fatal_fail("failed to stream request body: " .. err)
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
		-- deny the request if the content length is larger than client_body_buffer_size
		-- to avoid wasting resources on ruleset matching of very large data sets
		ngx.req.read_body()
		if (ngx.req.get_body_file() == nil) then
			return ngx.req.get_post_args()
		else
			_log(self, "very large form upload, not parsing")
			_rule_action(self, "DENY")
		end
	elseif (_table_has_value(self, content_type_header, self._allowed_content_types)) then
		-- users can whitelist specific content types that will be passed in but not parsed
		-- read the request in, but don't set collections[REQUEST_BODY]
		-- as we have no way to know what kind of data we're getting (i.e xml/json/octet stream)
		ngx.req.read_body()
		return nil
	else
		_log(self, tostring(content_type_header) .. " not a valid content type!")
		_rule_action(self, "DENY")
	end
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
		compress_whitespace = function(self, value)
			return ngx.re.gsub(value, [=[\s+]=], ' ', self._pcre_flags)
		end,
		html_decode = function(self, value)
			local str = ngx.re.gsub(value, [=[&lt;]=], '<', self._pcre_flags)
			str = ngx.re.gsub(str, [=[&gt;]=], '>', self._pcre_flags)
			str = ngx.re.gsub(str, [=[&quot;]=], '"', self._pcre_flags)
			str = ngx.re.gsub(str, [=[&apos;]=], "'", self._pcre_flags)
			str = ngx.re.gsub(str, [=[&#(\d+);]=], function(n) return string.char(n[1]) end, self._pcre_flags)
			str = ngx.re.gsub(str, [=[&#x(\d+);]=], function(n) return string.char(tonumber(n[1],16)) end, self._pcre_flags)
			str = ngx.re.gsub(str, [=[&amp;]=], '&', self._pcre_flags)
			_log(self, "html decoded value is " .. str)
			return str
		end,
		lowercase = function(self, value)
			return string.lower(tostring(value))
		end,
		remove_comments = function(self, value)
			return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], '', self._pcre_flags)
		end,
		remove_whitespace = function(self, value)
			return ngx.re.gsub(value, [=[\s+]=], '', self._pcre_flags)
		end,
		replace_comments = function(self, value)
			return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', self._pcre_flags)
		end,
		uri_decode = function(self, value)
			return ngx.unescape_uri(value)
		end,
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

-- process an individual rule
-- note that using a local per-request table to pass transient data
-- is more efficient than using ngx.ctx
local function _process_rule(self, rule, collections, ctx)
	local id = rule.id
	local var = rule.var
	local opts = rule.opts
	local action = rule.action
	local description = rule.description
	local pattern = var.pattern

	ctx.id = id
	ctx.rule_score = opts.score

	if (opts.setvar) then
		ctx.rule_setvar_key = opts.setvar.key
		ctx.rule_setvar_value = opts.setvar.value
		ctx.rule_setvar_expire = opts.setvar.expire
	end

	local t, match

	_log(self, type(collections[var.type]))
	if (type(collections[var.type]) == "function") then -- dynamic collection data - pers. storage, score, etc
		t = collections[var.type](self, var.opts, collections)
	else
		local memokey
		if (var.opts ~= nil) then
			memokey = var.type .. tostring(var.opts.key) .. tostring(var.opts.value)
		else
			memokey = var.type
		end
		memokey = memokey .. _transform_memokey(opts.transform)

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
	end

	if (not t) then
		_log(self, "parse_collection didnt return anything for " .. var.type)
		return rule.offset_nomatch
	else
		if (opts.parsepattern) then
			_log(self, "parsing dynamic pattern: " .. pattern)
			pattern = _parse_dynamic_value(self, pattern, collections)
		end
		match = operators[var.operator](self, t, pattern, ctx)
		if (match) then
			_log(self, "Match of rule " .. id .. "!")

			if (not opts.nolog) then
				_log_event(self, collections["IP"], collections["URI"], rule, match, ctx)
			else
				_log(self, "We had a match, but not logging because opts.nolog is set")
			end

			_rule_action(self, action, ctx, collections)
			return rule.offset_match
		else
			return rule.offset_nomatch
		end
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
	local request_post_args = _parse_request_body(self, request_headers)
	local cookies = cookiejar:new()
	local request_cookies, cookie_err = cookies:get_all()
	local request_common_args = _build_common_args(self, { request_uri_args, request_post_args, request_cookies })

	local ctx = {}
	ctx.altered = false
	ctx.log_entries = {}
	ctx.collections = {}
	ctx.collections_key = {}
	ctx.score = 0

	-- link rule collections to request data
	-- unlike the operators and actions lookup table,
	-- this needs data specific to each individual request
	-- so we have to instantiate it here
	local collections = {
		IP = request_client,
		HTTP_VERSION = request_http_version,
		METHOD = request_method,
		URI = request_uri,
		URI_ARGS = request_uri_args,
		HEADERS = request_headers,
		HEADER_NAMES = _table_keys(self, request_headers),
		USER_AGENT = request_ua,
		COOKIES = request_cookies,
		REQUEST_BODY = request_post_args,
		REQUEST_ARGS = request_common_args,
		VAR = function(self, opts, collections) return _get_var(self, opts.value, collections) end,
		SCORE = function() return ctx.score end,
		SCORE_THRESHOLD = function(self) return self._score_threshold end,
		WHITELIST = function(self) return self._whitelist end,
		BLACKLIST = function(self) return self._blacklist end,
	}

	for _, ruleset in ipairs(self._active_rulesets) do
		_log(self, "Beginning ruleset " .. ruleset)

		_log(self, "Requiring " .. ruleset)
		local rs = require("FreeWAF.rules." .. ruleset)

		local offset = 1
		while offset do
			local rule = rs.rules[offset]
			if (not _table_has_key(self, rule.id, self._ignored_rules)) then
				local ret = _process_rule(self, rule, collections, ctx)
				if (ret) then
					offset = offset + ret
				else
					offset = nil
				end
			else
				_log(self, "Ignoring rule " .. rule.id)
				offset = offset + rule.offset_nomatch
			end
		end
	end

	_finalize(self, ctx)
end -- fw.exec()

-- instantiate a new instance of the module
function _M.new(self)
	return setmetatable({
		_mode = "SIMULATE",
		_whitelist = {},
		_blacklist = {},
		_active_rulesets = _global_active_rulesets,
		_ignored_rules = {},
		_allowed_content_types = {},
		_debug = false,
		_debug_log_level = ngx.INFO,
		_event_log_level = ngx.INFO,
		_event_log_verbosity = 1,
		_event_log_target = 'error',
		_event_log_target_host = '',
		_event_log_target_port = '',
		_event_log_target_path = '',
		_event_log_buffer_size = 4096,
		_event_log_periodic_flush = nil,
		_event_log_altered_only = true,
		_pcre_flags = 'oij',
		_score_threshold = 5,
		_storage_zone = nil
	}, mt)
end

-- configuraton wrapper
function _M.set_option(self, option, value)
	local lookup = {
		whitelist = function(value)
			local t = self._whitelist
			self._whitelist[#t + 1] = value
		end,
		blacklist = function(value)
			local t = self._blacklist
			self._blacklist[#t + 1] = value
		end,
		ignore_ruleset = function(value)
			local t = {}
			local n = 1
			for k, v in ipairs(self._active_rulesets) do
				if (v ~= value) then
					t[n] = v
					n = n + 1
				end
			end
			self._active_rulesets = t
		end,
		ignore_rule = function(value)
			self._ignored_rules[value] = true
		end,
		disable_pcre_optimization = function(value)
			if (value == true) then
				self._pcre_flags = 'i'
			end
		end,
		storage_zone = function(value)
			if (not ngx.shared[value]) then
				_fatal_fail("Attempted to set FreeWAF storage zone as " .. tostring(value) .. ", but that lua_shared_dict does not exist")
			end
			self._storage_zone = value
		end,
		allowed_content_types = function(value)
			local t = self._allowed_content_types
			self._allowed_content_types[#t + 1] = value
		end
	}

	if (type(value) == "table") then
		for _, v in ipairs(value) do
			_M.set_option(self, option, v)
		end
	else
		if (lookup[option]) then
			lookup[option](value)
		else
			local _option = "_" .. option
			self[_option] = value
		end
	end

end

-- preload rulesets and calculate offsets
function _M.init()
	local calc = require "FreeWAF.lib.rule_calc"

	for _, ruleset in ipairs(_global_active_rulesets) do
		local r = require("FreeWAF.rules." .. ruleset)
		calc.calculate(r.rules)
	end
end

return _M
