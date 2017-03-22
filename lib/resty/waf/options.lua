local _M = {}

local actions = require "resty.waf.actions"
local base    = require "resty.waf.base"
local logger  = require "resty.waf.log"
local util    = require "resty.waf.util"

_M.version = base.version

_M.crs_config = {
	"PARANOIA_LEVEL", 1,
	"CRITICAL_ANOMALY_SCORE", 5,
	"ERROR_ANOMALY_SCORE", 4,
	"WARNING_ANOMALY_SCORE", 3,
	"NOTICE_ANOMALY_SCORE", 2,
	"INBOUND_ANOMALY_SCORE_THRESHOLD", 5,
	"OUTBOUND_ANOMALY_SCORE_THRESHOLD", 4,
	"ALLOWED_METHODS", "GET HEAD POST OPTIONS",
	"ALLOWED_REQUEST_CONTENT_TYPE", "application/x-www-form-urlencoded|multipart/form-data|text/xml|application/xml|application/x-amf|application/json|text/plain",
	"ALLOWED_HTTP_VERSIONS", "HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0",
	"RESTRICTED_EXTENSIONS", ".asa/ .asax/ .ascx/ .axd/ .backup/ .bak/ .bat/ .cdx/ .cer/ .cfg/ .cmd/ .com/ .config/ .conf/ .cs/ .csproj/ .csr/ .dat/ .db/ .dbf/ .dll/ .dos/ .htr/ .htw/ .ida/ .idc/ .idq/ .inc/ .ini/ .key/ .licx/ .lnk/ .log/ .mdb/ .old/ .pass/ .pdb/ .pol/ .printer/ .pwd/ .resources/ .resx/ .sql/ .sys/ .vb/ .vbs/ .vbproj/ .vsdisco/ .webinfo/ .xsd/ .xsx/",
	"RESTRICTED_HEADERS", "/proxy/ /lock-token/ /content-range/ /translate/ /if/",
	"STATIC_EXTENSIONS", "/.jpg/ /.jpeg/ /.png/ /.gif/ /.js/ /.css/ /.ico/ /.svg/ /.webp/",
	"MAX_NUM_ARGS", 255,
	"ARG_NAME_LENGTH", 100,
	"ARG_LENGTH", 400,
	"TOTAL_ARG_LENGTH", 64000,
	"MAX_FILE_SIZE", 1048576,
	"COMBINED_FILE_SIZES", 1048576,
	"DOS_BURST_TIME_SLICE", 60,
	"DOS_COUNTER_THRESHOLD", 100,
	"DOS_BLOCK_TIMEOUT", 600,
	"CRS_SETUP_VERSION", 300,
}

_M.lookup = {
	ignore_ruleset = function(waf, value)
		waf._ignore_ruleset[#waf._ignore_ruleset + 1] = value
		waf.need_merge = true
	end,
	add_ruleset = function(waf, value)
		waf._add_ruleset[#waf._add_ruleset + 1] = value
		waf.need_merge = true
	end,
	add_ruleset_string = function(waf, value, ruleset)
		waf._add_ruleset_string[value] = ruleset
		waf.need_merge = true
	end,
	ignore_rule = function(waf, value)
		waf._ignore_rule[value] = true
	end,
	disable_pcre_optimization = function(waf, value)
		logger.deprecate(waf, 'PCRE flags will force JIT/cache', '0.12')
		if value == true then
			waf._pcre_flags = 'i'
		end
	end,
	storage_zone = function(waf, value)
		if not ngx.shared[value] then
			logger.fatal_fail("Attempted to set lua-resty-waf storage zone as " .. tostring(value) .. ", but that lua_shared_dict does not exist")
		end
		waf._storage_zone = value
	end,
	allowed_content_types = function(waf, value)
		waf._allowed_content_types[value] = true
	end,
	res_body_mime_types = function(waf, value)
		waf._res_body_mime_types[value] = true
	end,
	event_log_ngx_vars = function(waf, value)
		waf._event_log_ngx_vars[value] = true
	end,
	nameservers = function(waf, value)
		waf._nameservers[#waf._nameservers + 1] = value
	end,
	hook_action = function(waf, value, hook)
		if not util.table_has_key(value, actions.disruptive_lookup) then
			logger.fatal_fail(value .. " is not a valid action to override")
		end

		if type(hook) ~= "function" then
			logger.fatal_fail("hook_action must be defined as a function")
		end

		waf._hook_actions[value] = hook
	end,
}

return _M
