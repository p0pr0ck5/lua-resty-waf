local _M = {}

_M.version = "0.5.2"

local ac = require("inc.load_ac")
local cjson = require("cjson")
local cookiejar = require("inc.resty.cookie")
local upload = require("inc.resty.upload")

local logger  = require("lib.log")
local lookup  = require("lib.lookup")
local storage = require("lib.storage")
local util    = require("lib.util")

local mt = { __index = _M }

-- default list of rulesets (global here to have offsets precomputed)
_global_active_rulesets = { 10000, 11000, 20000, 21000, 35000, 40000, 41000, 42000, 90000, 99000 }

-- get a subset or superset of request data collection
local function _parse_collection(self, collection, opts)
	if (type(collection) ~= "table") then
		return collection
	end

	if (opts == nil) then
		return collection
	end

	return lookup.parse_collection[opts.key](self, collection, opts.value)
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
				logger.log(self, "t[" .. k .. "] contains " .. tostring(t[k]))
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
	if (not ctx.altered and self._event_log_altered_only) then
		logger.log(self, "Not logging a request that wasn't altered")
		return
	end

	for _, entry in ipairs(ctx.log_entries) do
		lookup.write_log_events[self._event_log_target](self, entry)
	end

	-- clear log entries so we don't write duplicates
	ctx.log_entries = {}
end

-- cleanup
local function _finalize(self, ctx)
	-- write out any log events from this transaction
	_write_log_events(self, ctx)

	-- store the local copy of the ctx table
	ngx.ctx = ctx
end

-- use the lookup table to figure out what to do
local function _rule_action(self, action, ctx, collections)
	if (util.table_has_key(self, action, lookup.alter_actions)) then
		ctx.altered = true
		_finalize(self, ctx)
	end

	lookup.actions[action](self, ctx, collections)
end

-- handle request bodies
local function _parse_request_body(self, request_headers)
	local content_type_header = request_headers["content-type"]

	-- multiple content-type headers are likely an evasion tactic
	-- or result from misconfigured proxies. may consider relaxing
	-- this or adding an option to disable this checking in the future
	if (type(content_type_header) == "table") then
		logger.log(self, "request contained multiple content-type headers, bailing!")
		ngx.exit(400)
	end

	-- ignore the request body if no Content-Type header is sent
	-- this does technically violate the RFC
	-- but its necessary for us to properly handle the request
	-- and its likely a sign of nogoodnickery anyway
	if (not content_type_header) then
		logger.log(self, "request has no content type, ignoring the body")
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
		-- deny the request if the content length is larger than client_body_buffer_size
		-- to avoid wasting resources on ruleset matching of very large data sets
		ngx.req.read_body()
		if (ngx.req.get_body_file() == nil) then
			return ngx.req.get_post_args()
		else
			logger.log(self, "very large form upload, not parsing")
			_rule_action(self, "DENY")
		end
	elseif (util.table_has_value(self, content_type_header, self._allowed_content_types)) then
		-- users can whitelist specific content types that will be passed in but not parsed
		-- read the request in, but don't set collections[REQUEST_BODY]
		-- as we have no way to know what kind of data we're getting (i.e xml/json/octet stream)
		ngx.req.read_body()
		return nil
	else
		logger.log(self, tostring(content_type_header) .. " not a valid content type!")
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
	-- create a new tmp table to hold the transformed values
	local t = {}

	if (type(transform) == "table") then
		t = collection
		for k, v in ipairs(transform) do
			t = _do_transform(self, t, transform[k])
		end
	else
		-- if the collection is a table, loop through it and add the values to the tmp table
		-- otherwise, this returns directly to _process_rule or a recursed call from multiple transforms
		if (type(collection) == "table") then
			for k, v in pairs(collection) do
				t[k] = _do_transform(self, collection[k], transform)
			end
		else
			if (not collection) then
				return collection -- dont transform if the collection was nil, i.e. a specific arg key dne
			end

			logger.log(self, "doing transform of type " .. transform .. " on collection value " .. tostring(collection))
			return lookup.transform[transform](self, collection)
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

		logger.log(self, "checking for memokey " .. memokey)

		if (not ctx.collections_key[memokey]) then
			logger.log(self, "parsing collections for rule " .. id)
			t = _parse_collection(self, collections[var.type], var.opts)
			if (opts.transform) then
				t = _do_transform(self, t, opts.transform)
			end
			ctx.collections[memokey] = t
			ctx.collections_key[memokey] = true
		else
			logger.log(self, "parse collection cache hit!")
			t = ctx.collections[memokey]
		end
	end

	if (not t) then
		logger.log(self, "parse_collection didnt return anything for " .. var.type)
		return rule.offset_nomatch
	else
		if (opts.parsepattern) then
			logger.log(self, "parsing dynamic pattern: " .. pattern)
			pattern = util.parse_dynamic_value(self, pattern, collections)
		end
		match = lookup.operators[var.operator](self, t, pattern, ctx)
		if (match) then
			logger.log(self, "Match of rule " .. id .. "!")

			if (not opts.nolog) then
				_log_event(self, collections["IP"], collections["URI"], rule, match, ctx)
			else
				logger.log(self, "We had a match, but not logging because opts.nolog is set")
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
		logger.log(self, "Operational mode is INACTIVE, not running")
		return
	end

	local phase = ngx.get_phase()

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

	local ctx = ngx.ctx
	ctx.altered = ctx.altered or false
	ctx.log_entries = ctx.log_entries or {}
	ctx.collections = ctx.collections or {}
	ctx.collections_key = ctx.collections_key or {}
	ctx.score = ctx.score or 0

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
		HEADER_NAMES = util.table_keys(request_headers),
		USER_AGENT = request_ua,
		COOKIES = request_cookies,
		REQUEST_BODY = request_post_args,
		REQUEST_ARGS = request_common_args,
		VAR = function(self, opts, collections) return storage.get_var(self, opts.value, collections) end,
		SCORE = function() return ctx.score end,
		SCORE_THRESHOLD = function(self) return self._score_threshold end,
		WHITELIST = function(self) return self._whitelist end,
		BLACKLIST = function(self) return self._blacklist end,
	}

	for _, ruleset in ipairs(self._active_rulesets) do
		logger.log(self, "Beginning ruleset " .. ruleset)

		local rs = require("rules." .. ruleset)

		local offset = 1
		local rule = rs.rules[phase][offset]
		while rule do
			if (not util.table_has_key(self, rule.id, self._ignored_rules)) then
				local ret = _process_rule(self, rule, collections, ctx)
				if (ret) then
					offset = offset + ret
				else
					offset = nil
				end
			else
				logger.log(self, "Ignoring rule " .. rule.id)
				offset = offset + rule.offset_nomatch
			end
			rule = rs.rules[phase][offset]
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
	if (type(value) == "table") then
		for _, v in ipairs(value) do
			_M.set_option(self, option, v)
		end
	else
		if (lookup.set_option[option]) then
			lookup.set_option[option](self, value)
		else
			local _option = "_" .. option
			self[_option] = value
		end
	end

end

-- preload rulesets and calculate offsets
function _M.init()
	local calc  = require "lib.rule_calc"
	local phase = require "lib.phase"

	for _, ruleset in ipairs(_global_active_rulesets) do
		local r = require("rules." .. ruleset)

		for phase, i in pairs(phase.phases) do
			if (r.rules[phase]) then
				calc.calculate(r.rules[phase])
			else
				r.rules[phase] = {}
			end
		end
	end
end

return _M
