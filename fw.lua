local _M = {}

_M.version = "0.5.2"

local ac = require("inc.load_ac")
local cjson = require("cjson")

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

		if (not ctx.transform_key[memokey]) then
			logger.log(self, "parsing collections for rule " .. id)
			t = _parse_collection(self, collections[var.type], var.opts)
			if (opts.transform) then
				t = _do_transform(self, t, opts.transform)
			end
			ctx.transform[memokey] = t
			ctx.transform_key[memokey] = true
		else
			logger.log(self, "parse collection cache hit!")
			t = ctx.transform[memokey]
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

	local phase       = ngx.get_phase()
	local ctx         = ngx.ctx
	local collections = ctx.collections or {}

	ctx.altered       = ctx.altered or false
	ctx.log_entries   = ctx.log_entries or {}
	ctx.transform     = ctx.transform or {}
	ctx.transform_key = ctx.transform_key or {}
	ctx.score         = ctx.score or 0

	-- see https://groups.google.com/forum/#!topic/openresty-en/LVR9CjRT5-Y
	if (ctx.altered) then
		logger.log(self, "Transaction was already altered, not running!")
		return
	end

	-- populate the collections table
	lookup.collections[phase](self, collections, ctx)

	-- store the collections table in ctx, which will get saved to ngx.ctx
	ctx.collections = collections

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
