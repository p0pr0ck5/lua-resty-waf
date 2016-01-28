local _M = {}

_M.version = "0.6.0"

local calc    = require "lib.rule_calc"
local logger  = require("lib.log")
local lookup  = require("lib.lookup")
local phase_t = require("lib.phase")
local random  = require("lib.random")
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
local function _log_event(self, rule, match, ctx)
	local t = {
		id    = rule.id,
		match = match
	}

	if (self._event_log_verbosity > 1) then
		t.description = rule.description
	end

	if (self._event_log_verbosity > 2) then
		t.opts   = rule.opts
		t.action = rule.action
	end

	if (self._event_log_verbosity > 3) then
		t.var = rule.var
	end

	ctx.log_entries[#ctx.log_entries + 1] = t
end

-- restore options from a previous phase
local function _load(self, opts)
	for k, v in pairs(opts) do
		self[k] = v
	end
end

-- save options to the ctx table to be used in another phase
local function _save(self, ctx)
	local opts = {}

	for k, v in pairs(self) do
		opts[k] = v
	end

	ctx.opts = opts
end

local function _transaction_id_header(self, ctx)
	-- upstream request header
	if (self._req_tid_header) then
		ngx.req.set_header("X-FreeWAF-ID", self.transaction_id)
	end

	-- downstream response header
	if (self._res_tid_header) then
		ngx.header["X-FreeWAF-ID"] = self.transaction_id
	end

	ctx.t_header_set = true
end

-- cleanup
local function _finalize(self, ctx)
	-- set X-FreeWAF-ID headers as appropriate
	if (not ctx.t_header_set) then
		_transaction_id_header(self, ctx)
	end

	-- save our options for the next phase
	_save(self, ctx)

	-- store the local copy of the ctx table
	ngx.ctx = ctx
end

-- use the lookup table to figure out what to do
local function _rule_action(self, action, ctx, collections)
	if (util.table_has_key(action, lookup.alter_actions)) then
		ctx.altered[ctx.phase] = true
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
local function _process_rule(self, rule, collections, ctx)
	local id      = rule.id
	local var     = rule.var
	local opts    = rule.opts
	local action  = rule.action
	local pattern = var.pattern

	ctx.id = id
	ctx.rule_score = opts.score

	if (opts.setvar) then
		ctx.rule_setvar_key    = opts.setvar.key
		ctx.rule_setvar_value  = opts.setvar.value
		ctx.rule_setvar_expire = opts.setvar.expire
	end

	local t, match, offset

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

		logger.log(self, "Checking for memokey " .. memokey)

		if (not ctx.transform_key[memokey]) then
			logger.log(self, "Parse collection cache not found")
			t = _parse_collection(self, collections[var.type], var.opts)

			if (opts.transform) then
				t = _do_transform(self, t, opts.transform)
			end

			ctx.transform[memokey] = t
			ctx.transform_key[memokey] = true
		else
			logger.log(self, "Parse collection cache hit!")
			t = ctx.transform[memokey]
		end
	end

	if (not t) then
		logger.log(self, "parse_collection didnt return anything for " .. var.type)
		offset = rule.offset_nomatch
	else
		if (opts.parsepattern) then
			logger.log(self, "Parsing dynamic pattern: " .. pattern)
			pattern = util.parse_dynamic_value(self, pattern, collections)
		end

		match = lookup.operators[var.operator](self, t, pattern, ctx)

		if (match) then
			logger.log(self, "Match of rule " .. id)

			if (not opts.nolog) then
				_log_event(self, rule, match, ctx)
			else
				logger.log(self, "We had a match, but not logging because opts.nolog is set")
			end

			_rule_action(self, action, ctx, collections)

			offset = rule.offset_match
		else
			offset = rule.offset_nomatch
		end
	end

	logger.log(self, "Returning offset " .. tostring(offset))
	return offset
end

-- calculate rule jump offsets
local function _calculate_offset(ruleset)
	local r = require("rules." .. ruleset)

	for phase, i in pairs(phase_t.phases) do
		if (r.rules[phase]) then
			calc.calculate(r.rules[phase])
		else
			r.rules[phase] = {}
		end
	end

	r.initted = true
end

-- main entry point
function _M.exec(self)
	if (self._mode == "INACTIVE") then
		logger.log(self, "Operational mode is INACTIVE, not running")
		return
	end

	local phase = ngx.get_phase()

	if (not phase_t.is_valid_phase(phase)) then
		logger.fatal_fail("FreeWAF should not be run in phase " .. phase)
	end

	local ctx         = ngx.ctx
	local collections = ctx.collections or {}


	-- restore options from a previous phase
	if (ctx.opts) then
		_load(self, ctx.opts)
	end

	ctx.altered       = ctx.altered or {}
	ctx.log_entries   = ctx.log_entries or {}
	ctx.transform     = ctx.transform or {}
	ctx.transform_key = ctx.transform_key or {}
	ctx.score         = ctx.score or 0
	ctx.t_header_set  = ctx.t_header_set or false
	ctx.phase         = phase

	-- see https://groups.google.com/forum/#!topic/openresty-en/LVR9CjRT5-Y
	if (ctx.altered[phase]) then
		logger.log(self, "Transaction was already altered, not running!")
		return
	end

	-- populate the collections table
	local short_circuit = lookup.collections[phase](self, collections, ctx)

	-- don't run through the rulesets if we're going to be here again
	-- (e.g. multiple chunks are going through body_filter)
	if short_circuit then return end

	-- store the collections table in ctx, which will get saved to ngx.ctx
	ctx.collections = collections

	logger.log(self, "Beginning run of phase " .. phase)

	for _, ruleset in ipairs(self._active_rulesets) do
		logger.log(self, "Beginning ruleset " .. ruleset)

		local rs = require("rules." .. ruleset)

		if (not rs.initted) then
			logger.log(self, "Doing offset calculation of " .. ruleset)
			_calculate_offset(ruleset)
		end

		local offset = 1
		local rule   = rs.rules[phase][offset]

		while rule do
			local id = rule.id

			if (not util.table_has_key(id, self._ignored_rules)) then
				logger.log(self, "Processing rule " .. id)

				local ret = _process_rule(self, rule, collections, ctx)
				if (ret) then
					offset = offset + ret
				else
					offset = nil
				end
			else
				logger.log(self, "Ignoring rule " .. id)
				offset = offset + rule.offset_nomatch
			end

			rule = rs.rules[phase][offset]
		end
	end

	_finalize(self, ctx)
end

-- instantiate a new instance of the module
function _M.new(self)
	return setmetatable({
		_mode                        = "SIMULATE",
		_whitelist                   = {},
		_blacklist                   = {},
		_active_rulesets             = _global_active_rulesets,
		_ignored_rules               = {},
		_allowed_content_types       = {},
		_debug                       = false,
		_debug_log_level             = ngx.INFO,
		_event_log_level             = ngx.INFO,
		_event_log_verbosity         = 1,
		_event_log_request_arguments = false,
		_event_log_request_headers   = false,
		_event_log_ngx_vars          = {},
		_event_log_target            = 'error',
		_event_log_target_host       = '',
		_event_log_target_port       = '',
		_event_log_target_path       = '',
		_event_log_socket_proto      = 'udp',
		_event_log_buffer_size       = 4096,
		_event_log_periodic_flush    = nil,
		_event_log_altered_only      = true,
		_res_body_max_size           = (1024 * 1024),
		_res_body_mime_types         = { "text/plain", "text/html" },
		_process_multipart_body      = true,
		_req_tid_header              = false,
		_res_tid_header              = true,
		_pcre_flags                  = 'oij',
		_score_threshold             = 5,
		_storage_zone                = nil,
		transaction_id               = random.random_bytes(10),
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

-- push log data regarding matching rule(s) to the configured target
-- in the case of socket or file logging, this data will be buffered
function _M.write_log_events(self)
	-- there is a small bit of code duplication here to get our context
	-- because this lives outside exec()
	local ctx = ngx.ctx
	if (ctx.opts) then
		_load(self, ctx.opts)
	end

	if (table.getn(util.table_keys(ctx.altered)) == 0 and self._event_log_altered_only) then
		logger.log(self, "Not logging a request that wasn't altered")
		return
	end

	if (#ctx.log_entries == 0) then
		logger.log(self, "Not logging a request that had no rule alerts")
		return
	end

	local entry = {
		timestamp = ngx.time(),
		client    = ctx.collections["IP"],
		method    = ctx.collections["METHOD"],
		uri       = ctx.collections["URI"],
		alerts    = ctx.log_entries,
		score     = ctx.score,
		id        = self.transaction_id,
	}

	if self._event_log_request_arguments then
		entry.uri_args = ctx.collections["URI_ARGS"]
	end

	if self._event_log_request_headers then
		entry.request_headers = ctx.collections["REQUEST_HEADERS"]
	end

	if (table.getn(self._event_log_ngx_vars) ~= 0) then
		entry.ngx = {}
		for _, k in ipairs(self._event_log_ngx_vars) do
			entry.ngx[k] = ngx.var[k]
		end
	end

	lookup.write_log_events[self._event_log_target](self, entry)
end

return _M
