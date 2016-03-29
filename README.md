##Name

FreeWAF - High-performance WAF built on the OpenResty stack

##Table of Contents

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Requirements](#requirements)
* [Performance](#performance)
* [Installation](#installation)
* [Synopsis](#synopsis)
* [Public Functions](#public-functions)
	* [FreeWAF.default_option()](#freewafdefault_option)
	* [FreeWAF.init()](#freewafinit)
* [Public Methods](#public-methods)
	* [FreeWAF:new()](#freewafnew)
	* [FreeWAF:set_option()](#freewafset_option)
	* [FreeWAF:reset_option()](#freewafreset_option)
	* [FreeWAF:write_log_events()](#freewafwrite_log_events)
* [Options](#options)
	* [allow_unknown_content_types](#allow_unknown_content_types)
	* [allowed_content_types](#allowed_content_types)
	* [debug](#debug)
	* [debug_log_level](#debug_log_level)
	* [disable_pcre_optimization](#disable_pcre_optimization)
	* [event_log_altered_only](#event_log_altered_only)
	* [event_log_buffer_size](#event_log_buffer_size)
	* [event_log_level](#event_log_level)
	* [event_log_ngx_vars](#event_log_ngx_vars)
	* [event_log_periodic_flush](#event_log_periodic_flush)
	* [event_log_request_arguments](#event_log_request_arguments)
	* [event_log_request_headers](#event_log_request_headers)
	* [event_log_socket_proto](#event_log_socket_proto)
	* [event_log_target](#event_log_target)
	* [event_log_target_host](#event_log_target_host)
	* [event_log_target_path](#event_log_target_path)
	* [event_log_target_port](#event_log_target_port)
	* [event_log_verbosity](#event_log_verbosity)
	* [ignore_rule](#ignore_rule)
	* [ignore_ruleset](#ignore_ruleset)
	* [mode](#mode)
	* [process_multipart_body](#process_multipart_body)
	* [score_threshold](#score_threshold)
	* [storage_zone](#storage_zone)
	* [res_body_max_size](#res_body_max_size)
	* [res_body_mime_types](#res_body_mime_types)
	* [req_tid_header](#req_tid_header)
	* [res_tid_header](#res_tid_header)
* [Phase Handling](#phase-handling)
* [Included Rulesets](#included-rulesets)
* [Rule Definitions](#rule-definitions)
* [Notes](#notes)
	* [Community](#community)
	* [Pull Requests](#pull-requests)
* [Roadmap](#roadmap)
* [Limitaions](#limitations)
* [License](#license)
* [Bugs](#bugs)
* [See Also](#see-also)

##Status

[![Build Status](https://travis-ci.org/p0pr0ck5/FreeWAF.svg?branch=development)](https://travis-ci.org/p0pr0ck5/FreeWAF)

FreeWAF is currently in active development. New bugs and questions opened in the issue tracker will be answered within a day or two, and performance impacting / security related issues will be patched with high priority. Larger feature sets and enhancements will be added when development resources are available (see the [Roadmap](#roadmap) section for an outline of planned features).

FreeWAF is compatible with the master branch of `lua-resty-core`. The bundled version of `lua-resty-core` available in the current release of OpenResty (>= 1.9.7.4) is compatible with FreeWAF; versions bundled with older OpenResty bundles are not, so users wanting to leverage `resty.core` will either need to replace the local version with the one available from the [GitHub project](https://github.com/openresty/lua-resty-core), or patch the module based off [this commit](https://github.com/openresty/lua-resty-core/commit/40445b12c0359eb82702f0097cd65948c245b6a4).

##Description

FreeWAF is a reverse proxy WAF built using the OpenResty stack. It uses the Nginx Lua API to analyze HTTP request information and process against a flexible rule structure. FreeWAF is distributed with a ruleset that mimics the ModSecurity CRS, as well as a few custom rules built during initial development and testing, and a small virtual patchset for emerging threats. Additionally, FreeWAF is distributed with tooling to automatically translate existing ModSecurity rules, allowing users to extend FreeWAF implementation without the need to learn a new rule syntax.

FreeWAF was initially developed by Robert Paprocki for his Master's thesis at Western Governor's University.

##Requirements

FreeWAF requires several third-party resty lua modules, though these are all packaged with FreeWAF, and thus do not need to be installed separately. It is recommended to install FreeWAF on a system running the OpenResty software bundle; FreeWAF has not been tested on platforms built using separate Nginx source and Nginx Lua module packages.

For optimal regex compilation performance, it is recommended to build Nginx/OpenResty with a version of PCRE that supports JIT compilation. If your OS does not provide this, you can build JIT-capable PCRE directly into your Nginx/OpenResty build. To do this, reference the path to the PCRE source in the `--with-pcre` configure flag. For example:

```sh
	# ./configure --with-pcre=/path/to/pcre/source --with-pcre-jit
```

You can download the PCRE source from the [PCRE website](http://www.pcre.org/). See also this [blog post](https://www.cryptobells.com/building-openresty-with-pcre-jit/) for a step-by-step walkthrough on building OpenResty with a JIT-enabled PCRE library.

##Performance

FreeWAF was designed with efficiency and scalability in mind. It leverages Nginx's asynchronous processing model and an efficient design to process each transaction as quickly as possible. Load testing has show that deployments implementing all provided rulesets, which are designed to mimic the logic behind the ModSecurity CRS, process transactions in roughly 300-500 microseconds per request; this equals the performance advertised by [Cloudflare's WAF](https://www.cloudflare.com/waf). Tests were run on a reasonable hardware stack (E3-1230 CPU, 32 GB RAM, 2 x 840 EVO in RAID 0), maxing at roughly 15,000 requests per second. See [this blog post](http://www.cryptobells.com/freewaf-a-high-performance-scalable-open-web-firewall) for more information.

FreWAF workload is almost exclusively CPU bound. Memory footprint in the Lua VM (excluding persistent storage backed by `lua-shared-dict`) is roughly 2MB.

##Installation

Clone the FreeWAF repo into Nginx/OpenResty's Lua package path. Module setup and configuration is detailed in the synopsis.

Note that by default FreeWAF runs in SIMULATE mode, to prevent immediately affecting an application; users who wish to enable rule actions must explicitly set the operational mode to ACTIVE.

##Synopsis

```lua
	http {
		-- include FreeWAF in the appropriate paths
		lua_package_path '/usr/local/openresty/lualib/FreeWAF/?.lua;;';
		lua_package_cpath '/usr/local/openresty/lualib/FreeWAF/?.lua;;';

		-- use resty.core for performance improvement, see the status note above
		require "resty.core"

		-- require the base module
		local FreeWAF = require "fw"

		-- define options that will be inherited across all scopes
		FreeWAF.default_option("debug", true)
		FreeWAF.default_option("mode", "ACTIVE")

		-- perform some preloading and optimization
		FreeWAF.init()
	}

	server {
		location / {
			access_by_lua '
				local FreeWAF = require "fw"

				local fw = FreeWAF:new()

				-- default options can be overridden
				fw:set_option("debug", false)

				-- run the firewall
				fw:exec()
			';

			header_filter_by_lua '
				local FreeWAF = require "fw"

				-- note that options set in previous handlers (in the same scope)
				-- do not need to be set again
				local fw = FreeWAF:new()

				fw:exec()
			';

			body_filter_by_lua '
				local FreeWAF = require "fw"

				local fw = FreeWAF:new()

				fw:exec()
			';

			log_by_lua '
				local FreeWAF = require "fw"

				local fw = FreeWAF:new()

				-- write out any event log entries to the
				-- configured target, if applicable
				fw:write_log_events()
			';
		}
	}
```

##Public Functions

###FreeWAF.default_option()

Define default values for configuration options that will be inherited across all scopes. This is useful when you are using FreeWAF in many different scopes (i.e. many server blocks, locations, etc.), and don't want to have to make the same call to `set_option` many times. You do not have to call this function if you are not changing the value of the option from what is defined as the default.

```lua
	http {
		init_by_lua '
			local FreeWAF = require "fw"

			FreeWAF.default_option("debug", true)

			-- this would be a useless operation since it does not change the default
			FreeWAF.default_option("debug_log_level", ngx.INFO)
		';
	}
```

###FreeWAF.init()

Perform some pre-computation of rules and rulesets, based on what's been made available via the default distributed rulesets and those added or ignored via `default_option`. It's recommended, but not required, to call this function (not doing so will result in a small performance penalty). This function should be called after any FreeWAF function call in `init_by_lua`, and should never be called outside this scope.

*Example*:

```lua
	http {
		init_by_lua '
			local FreeWAF = require "fw"

			-- set default options...

			FreeWAF.init()
		';
	}
```

##Public Methods

###FreeWAF:new()

Instantiate a new instance of FreeWAF. You must call this in every request handler phase you wish to run FreeWAF, and use the return result to call further object methods.

*Example*:

```lua
	location / {
		access_by_lua '
			local FreeWAF = require "fw"

			local fw = FreeWAF:new()
		';
	}
```

###FreeWAF:set_option()

Configure an option on a per-scope basis. You should only do this if you are overriding a default value in this scope (e.g. it would be useless to use this to define the same configurable everywhere).

*Example*:

```lua
	location / {
		access_by_lua '
			local FreeWAF = require "fw"

			local fw = FreeWAF:new()

			-- enable debug logging only for this scope
			fw:set_option("debug", true)
		';
	}
```

###FreeWAF:reset_option()

Set the given option to its documented default, regardless of whatever value was assigned via `default_option`. This is most useful for options that are more complex than boolean or integer values.

*Example*:

```lua
	http {
		init_by_lua '
			local FreeWAF = require "fw"

			FreeWAF.default_option("allowed_content_types", "text/json")
		';
	}

	[...snip...]

	location / {
		access_by_lua '
			local FreeWAF = require "fw"

			local fw = FreeWAF:new()

			-- reset the value to its documented default
			fw:reset_option("allowed_content_types")
		';
	}
```

###FreeWAF:write_log_events()

Write any audit log entries that were generated from the transaction. This should be called in the `log_by_lua` handler.

*Example*:

```lua
	location / {
		log_by_lua '
			local FreeWAF = require "fw"

			local fw = FreeWAF:new()

			-- write out any event log entries to the
			-- configured target, if applicable
			fw:write_log_events()
		';
	}
```

##Options

Module options can be configured using the `default_option` and `set_option` functions. Use `default_option` when in the `init_by_lua` handler, and without calling `FreeWAF:new()`, to set default values that will be inherited across all scopes. These values (or options that were not modified by `default_option` can be further adjusted on a per-scope basis via `set_option`. Additionally, scope-level options can be re-adjusted back to the documented defaults via the `reset_option` method. This will set the given option to its documented default, overriding the default set by the `default_option` function.

Note that options set in an earlier phase handler do not need to be re-set in a later phase, though they can be overwritten (i.e., you can set `debug` in the `access` phase, but disable it in `header_filter`. Details for available options are provided below.

###add_ruleset

*Default*: none

Adds an additional ruleset to be used during processing. This allows users to implement custom rulesets without stomping over the included rules directory. Additional rulesets much reside within a folder called "rules" that lives within the `lua_package_path`.

*Example*:

```lua
	http {
		-- the lua module 50000.lua must live at
		-- /path/to/extra/rulesets/rules/50000.lua
		lua_package_path '/path/to/extra/rulesets/?.lua;;';
	}

	location / {
		access_by_lua '
			fw:set_option("add_ruleset", 50000)
		';
	}
```

Multiple rulesets may be added by passing a table of values to `set_option`. Note that ruleset names must be numeric, as they are sorted for processing in numeric order. This also implies some level of control on the users part; because rulesets are processed in increasing numeric order, the order with which rulesets are passed to `set_option` does not matter. Note only that rulesets of a higher numeric value are processed after those of a lower value.

**NOTE: It is STRONGLY recommend avoiding adding rulesets via `set_option`. It is much safer to add rulesets globally via `default_option`, and ignore rulesets in necessary scopes. Loading a ruleset requires reading the rule from disk on first load; when done outside the `init` phase, this can block the nginx event loop. Caveat emptor.**

###allow_unknown_content_types

*Default*: false

Instructs FreeWAF to continue processing the request when a Content-Type header has been sent that is not in the `allowed_content_types` table. Such requests will not have their request body processed by FreeWAF (the `REQUEST_BODY` collection will be nil). In this manner, users do not need to explicitly whitelist all possible Content-Type headers they may encounter.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("allow_unknown_content_types", true)
		';
	}
```

###allowed_content_types

*Default*: none

Defines one or more Content-Type headers that will be allowed, in addition to the default Content-Types `application/x-www-form-urlencoded` and `multipart/form-data`. A request whose content type matches one of `allowed_content_types` will set the `REQUEST_BODY` collection to a single string containing (rather than a table); a request whose content type does not match one of these values, or `application/x-www-form-urlencoded` or `multipart/form-data`, will be rejected.

*Example*:


```lua
	location / {
		access_by_lua '
			-- define a single allowed Content-Type value
			fw:set_option("allowed_content_types", "text/xml")

			-- defines multiple allowed Content-Type values
			fw:set_option("allowed_content_types", { "text/html", "text/json", "application/json" })
		';
	}
```

Note that mutiple `set_option` calls with a parameter of `allowed_content_types` will simply override the existing options table, so if you want to define multiple allowed content types, you must define them as a Lua table as shown above.

###debug

*Default*: false

Disables/enables debug logging. Debug log statements are printed to the error_log. Note that debug logging is very expensive and should not be used in production environments.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("debug", true)
		';
	}
```

###debug_log_level

*Default*: ngx.INFO

Sets the nginx log level constant used for debug logging.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("debug_log_level", ngx.DEBUG)
		';
	}
```

###disable_pcre_optimization

*Default*: false

Removes the `oj` flags from all `ngx.re.match`, `ngx.re.find`, and `ngx.re.sub` calls. This may be useful in some cases where older PCRE libraries are used, but will cause severe performance degradation, so its use is strongly discouraged; users are instead encouraged to build OpenResty with a modern, JIT-capable PCRE library.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("disable_pcre_optimization", true)
		';
	}
```

###event_log_altered_only

*Default*: true

Determines whether to write log entries for rule matches in a transaction that was not altered by FreeWAF. "Altered" is defined as FreeWAF acting on a rule whose action is `ACCEPT` or `DENY`. When this option is unset, FreeWAF will log rule matches even if the transaction was not altered. By default, FreeWAF will only write log entries for matches if the transaction was altered.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_altered_only", false)
		';
	}
```

Note that `mode` will not have an effect on determing whether a transaction is considered altered. That is, if a rule with a `DENY` action is matched, but FreeWAF is running in `SIMULATE` mode, the transaction will still be considered altered, and rule matches will be logged.

###event_log_buffer_size

*Default*: 4096

Defines the threshold size, in bytes, of the buffer to be used to hold event logs. The buffer will be flushed when this threshold is met.

*Example*:

```lua
	location / {
		access_by_lua '
			-- 8 KB event log message buffer
			fw:set_option("event_log_buffer_size", 8192)
		';
	}
```

###event_log_level

*Default*: ngx.INFO

Sets the nginx log level constant used for event logging.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_level", ngx.WARN)
		';
	}
```

###event_log_ngx_vars

*Default*: empty

Defines what extra variables from `ngx.var` are put to the log event. This is a generic way to extend the alert with extra context. The variable name will be the key of the entry under an `ngx` key in the log entry. If the variable is not present as an nginx variable, no item is added to the event.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_ngx_vars", "host")
			fw:set_option("event_log_ngx_vars", "request_id")
		';
	}
```

The resulting event has these extra items:

```json
{
	"ngx": {
		"host": "example.com",
		"request_id": "373bcce584e3c18a"
	}
}
```

###event_log_periodic_flush

*Default*: none

Defines an interval, in seconds, at which the event log buffer will periodically flush. If no value is configured, the buffer will not flush periodically, and will only flush when the `event_log_buffer_size` threshold is reached. Configure this option for very low traffic sites that may not receive any event log data in a long period of time, to prevent stale data from sitting in the buffer.

*Example*:

```lua
	location / {
		access_by_lua '
			-- flush the event log buffer every 30 seconds
			fw:set_option("event_log_periodic_flush", 30)
		';
	}
```

###event_log_request_arguments

*Default*: false

When set to true, the log entries contain the request arguments under the `uri_args` key.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_request_arguments", true)
		';
	}
```

###event_log_request_headers

*Default*: false

The headers of the HTTP request is copied to the log event, under the `request_headers` key. 

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_request_headers", true)
		';
	}
```

The resulting event has these extra items:

```json
{
	"request_headers": {
		"accept": "*/*",
		"user-agent": "curl/7.22.0 (x86_64-pc-linux-gnu) libcurl/7.22.0 OpenSSL/1.0.1 zlib/1.2.3.4 libidn/1.23 librtmp/2.3"
	}
}
```

###event_log_socket_proto

*Default*: udp

Defines which IP protocol to use (TCP or UDP) when shipping event logs via a remote socket. The same buffering and recurring flush logic will be used regardless of protocol.

*Example*:

```lua
	location / {
		access_by_lua '
			-- send logs via TCP
			fw:set_option("event_log_socket_proto", "tcp")
		';
	}
```

###event_log_target

*Default*: error

Defines the destination for event logs. FreeWAF currently supports logging to the error log, a separate file on the local file system, or a remote TCP or UDP server. In the latter two cases, event logs are buffered and flushed when a defined threshold is reached (see below for further options regarding event logging options).

*Example*:

```lua
	location / {
		access_by_lua '
			-- send event logs to the server's error_log location (default)
			fw:set_option("event_log_target", "error")

			-- send event logs to a local file on disk
			fw:set_option("event_log_target", "file")

			-- send event logs to a remote server
			fw:set_option("event_log_target", "socket")
		';
	}
```

Note that, due to a limition in the logging library used, only a single target socket (and separate file target) can be defined. This is to say, you may elect to use both socket and file logging in different locations, but you may only configure one `socket` target with a specific host/port combination; if you configure a second host/port combination, data will not be properly logged. Similarly, you may only define one file path if using a `file` logging target; writes to a second path location will be lost.

###event_log_target_host

*Default*: none

Defines the target server for event logs that target a remote server.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_target_host", "10.10.10.10")
		';
	}
```

###event_log_target_path

*Default*: none

Defines the target path for event logs that target a local file system location.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_target_path", "/var/log/freewaf/event.log")
		';
	}
```

This path must be in a location writeable by the nginx user. Note that, by nature, on-disk logging can cause significant performance degredation in high-concurrency environments.

###event_log_target_port

*Default*: none

Defines the target port for event logs that target a remote server.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_target_port", 9001)
		';
	}
```

###event_log_verbosity

*Default*: 1

Sets the verbosity used in writing event log notification. The higher the verbosity, the more information will be included in the JSON blob generated for each notification.

*Example*:

```lua
	location / {
		access_by_lua '
			-- default verbosity. the client IP, request URI, rule match data, and rule ID will be logged
			fw:set_option("event_log_verbosity", 1)

			-- the rule description will be written in addition to existing data
			fw:set_option("event_log_verbosity", 2)

			-- the rule description, options and action will be written in addition to existing data
			fw:set_option("event_log_verbosity", 3)

			-- the entire rule definition, including the match pattern, will be written in addition to existing data
			-- note that for some rule definitions, such as the XSS and SQLi rulesets, this pattern can be large
			fw:set_option("event_log_verbosity", 4)
		';
	}
```

###ignore_rule

*Default*: none

Instructs the module to ignore a specified rule ID. Note that ignoring a rule in a chain will result in the entire chain being ignored, and processing will continue to the next rule following the chain.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("ignore_rule", 40294)
		';
	}
```

Multiple rules can be ignored by passing a table of rule IDs to `set_option`.

###ignore_ruleset

*Default*: none

Instructs the module to ignore an entire ruleset. This can be useful when some rulesets (such as the SQLi or XSS CRS rulesets) are too prone to false positives, or aren't applicable to your application.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("ignore_ruleset", 40000)
		';
	}
```

###mode

*Default*: SIMULATE

Sets the operational mode of the module. Options are ACTIVE, INACTIVE, and SIMULATE. In ACTIVE mode, rule matches are logged and actions are run. In SIMULATE mode, FreeWAF loops through each enabled rule and logs rule matches, but does not complete the action specified in a given run. INACTIVE mode prevents the module from running.

By default, SIMULATE is selected if a mode is not explicitly set; this requires new users to actively implement blocking by setting the mode to ACTIVE.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("mode", "ACTIVE")
		';
	}
```

###process_multipart_body

*Default* true

Enable processing of multipart/form-data request bodies (when present), using the `lua-resty-upload` module. In the future, FreeWAF may use this processing to perform stricter checking of upload bodies; for now this module performs only minimal sanity checks on the request body, and will not log an event if the request body is invalid. Disable this option if you do not need this checking, or if bugs in the upstream module are causing problems with HTTP uploads.

*Example*:

```lua
	location / {
		access_by_lua '
			-- disable processing of multipart/form-data requests
			-- note that the request body will still be sent to the upstream
			fw:set_option("process_multipart_body", false)
		';
	}
```

###score_threshold

*Default*: 5

Sets the threshold for anomaly scoring. When the threshold is reached, FreeWAF will deny the request.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("score_threshold", 10)
		';
	}
```

###storage_zone

*Default*: none

Defines the `lua_shared_dict` that will be used to hold persistent storage data. This zone must be defined in the `http{}` block of the configuration.

*Example*:

```lua
	http {
		-- define a 64M shared memory zone to hold persistent storage data
		lua_shared_dict persistent_storage 64m;
	}

	location / {
		access_by_lua '
			fw:set_option("storage_zone", "persistent_storage")
		';
	}
```

Multiple shared zones can be defined and used, though only one zone can be defined per configuration location. If a zone becomes full and the shared dictionary interface cannot add additional keys, the following will be entered into the error log:

`Could not add key to persistent storage, increase the size of the lua_shared_dict`

###res_body_max_size

*Default*: 1048576 (1 MB)

Defines the content length threshold beyond which response bodies will not be processed. This size of the response body is determined by the Content-Length response header. If this header does not exist in the response, the response body will never be processed.

*Example*:

```lua
	location / {
		access_by_lua '
			-- increase the max response size to 2 MB
			fw:set_option("res_body_max_size", 1024 * 1024 * 2)
		';
	}
```
Note that by nature, it is required to buffer the entire response body in order to properly use the response as a collection, so increasing this number significantly is not recommended without justification (and ample server resources).

###res_body_mime_types

*Default*: "text/plain", "text/html"

Defines the MIME types with which FreeWAF will process the response body. This value is determined by the Content-Type header. If this header does not exist, or the response type is not in this list, the response body will not be processed. Setting this option will add the given MIME type to the existing defaults of `text/plain` and `text/html`.

*Example*:

```lua
	location / {
		access_by_lua '
			-- mime types that will be processed are now text/plain, text/html, and text/json
			fw:set_option("res_body_mime_types", "text/json")
		';
	}
```

Multiple MIME types can be added by passing a table of types to `set_option`.

###req_tid_header

*Default*: false

Set an HTTP header `X-FreeWAF-ID` in the upstream request, with the value as the transaction ID. This ID will correlate with the transaction ID present in the debug logs (if set). This can be useful for request tracking or debug purposes.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("req_tid_header", true)
		';
	}
```

###res_tid_header

*Default*: false

Set an HTTP header `X-FreeWAF-ID` in the downstream response, with the value as the transaction ID. This ID will correlate with the transaction ID present in the debug logs (if set). This can be useful for request tracking or debug purposes.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("res_tid_header", true)
		';
	}
```

##Phase Handling

FreeWAF is designed to run in multiple phases of the request lifecycle. Rules can be processed in the following phases:

* **access**: Request information, such as URI, request headers, URI args, and request body are available in this phase.
* **header_filter**: Response headers and HTTP status are available in this phase.
* **body_filter**: Response body is available in this phase.

These phases correspond to their appropriate Nginx lua handlers (`access_by_lua`, `header_filter_by_lua`, and `body_filter_by_lua`, respectively). Note that running FreeWAF in a lua phase handler not in this list will lead to broken behavior. All data available in an earlier phase is available in a later phase. That is, data available in the `access` phase is also available in the `header_filter` and `body_filter` phases, but not vice versa.

Additionally, it is required to call `write_log_events` in a `log_by_lua` handler. FreeWAF is not designed to process rules in this phase; logging rules late in the request allows all rules to be coalesced into a single entry per request. See the synopsis above for example syntax.

##Included Rulesets

FreeWAF is distributed with a number of rulesets that are designed to mimic the functionality of the ModSecurity CRS. For reference, these rulesets are listed here:

* **11000**: Local policy whitelisting
* **20000**: HTTP protocol violation
* **21000**: HTTP protocol anomalies
* **35000**: Malicious/suspect user agents
* **40000**: Generic attacks
* **41000**: SQLi
* **42000**: XSS
* **90000**: Custom rules/virtual patching
* **99000**: Anomaly score handling

##Rule Definitions

FreeWAF parses rules definitions from JSON blobs stored on-disk. Rules are grouped based on purpose and severity, defined as a ruleset. The included rulesets were created to mimic some functionality of the ModSecurity CRS, particularly the `base_rules` definitions. Additionally, the included `modsec2freewaf.pl` script can be used to translate additional or custom rulesets to a FreeWAF-compatible JSON blob.

Note that there are several limitations in the translation script, with respect to unsupported actions, collections, and operators. Please see [this wiki page](https://github.com/p0pr0ck5/FreeWAF/wiki/Known-ModSecurity-Translation-Limitations) for an up-to-date list of known incompatibilities.

##Notes

###Community

There is a Freenode IRC channel `#freewaf`. Travis CI sends notifications here; feel free to ask questions/leave comments in this channel as well.

###Pull Requests

Please target all pull requests towards the development branch, or a feature branch if the PR is a significant change. Commits to master should only come in the form of documentation updates or other changes that have no impact of the module itself (and can be cleanly merged into development).

##Roadmap

* **Expanded virtual patch ruleset**: Increase coverage of emerging threats.
* **Expanded integration/acceptance testing**: Increase coverage of common threats and usage scenarios.
* **Expanded ModSecurity syntax translations**: Support more operators, variables, and actions.
* **Support for different/multiple persistent storage engines**: Memcached, redis, etc (in addition to ngx.shared).
* **Common application profiles**: Tuned rulesets for common CMS/applications.
* **Support multiple socket/file logger targets**: Likely requires forking the lua-resty-logger-socket project.

##Limitations

FreeWAF is undergoing continual development and improvement, and as such, may be limited in its functionality and performance. Currently known limitations can be found within the GitHub issue tracker for this repo.

##License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>

##Bugs

Please report bugs by creating a ticket with the GitHub issue tracker.

##See Also

- The OpenResty project: <http://openresty.org/>
- My personal blog for updates and notes on FreeWAF development: <http://www.cryptobells.com/tag/freewaf/>
