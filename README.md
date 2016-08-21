##Name

lua-resty-waf - High-performance WAF built on the OpenResty stack

##Table of Contents

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Requirements](#requirements)
* [Performance](#performance)
* [Installation](#installation)
* [Synopsis](#synopsis)
* [Public Functions](#public-functions)
	* [lua-resty-waf.default_option()](#lua-resty-wafdefault_option)
	* [lua-resty-waf.init()](#lua-resty-wafinit)
* [Public Methods](#public-methods)
	* [lua-resty-waf:new()](#lua-resty-wafnew)
	* [lua-resty-waf:set_option()](#lua-resty-wafset_option)
	* [lua-resty-waf:reset_option()](#lua-resty-wafreset_option)
	* [lua-resty-waf:write_log_events()](#lua-resty-wafwrite_log_events)
* [Options](#options)
	* [add_ruleset](#add_ruleset)
	* [add_ruleset_string](#add_ruleset_string)
	* [allow_unknown_content_types](#allow_unknown_content_types)
	* [allowed_content_types](#allowed_content_types)
	* [debug](#debug)
	* [debug_log_level](#debug_log_level)
	* [deny_status](#deny_status)
	* [disable_pcre_optimization](#disable_pcre_optimization)
	* [event_log_altered_only](#event_log_altered_only)
	* [event_log_buffer_size](#event_log_buffer_size)
	* [event_log_level](#event_log_level)
	* [event_log_ngx_vars](#event_log_ngx_vars)
	* [event_log_periodic_flush](#event_log_periodic_flush)
	* [event_log_request_arguments](#event_log_request_arguments)
	* [event_log_request_body](#event_log_request_body)
	* [event_log_request_headers](#event_log_request_headers)
	* [event_log_ssl](#event_log_ssl)
	* [event_log_ssl_sni_host](*event_log_ssl_sni_host)
	* [event_log_ssl_verify](*event_log_ssl_verify)
	* [event_log_socket_proto](#event_log_socket_proto)
	* [event_log_target](#event_log_target)
	* [event_log_target_host](#event_log_target_host)
	* [event_log_target_path](#event_log_target_path)
	* [event_log_target_port](#event_log_target_port)
	* [event_log_verbosity](#event_log_verbosity)
	* [hook_action](#hook_action)
	* [ignore_rule](#ignore_rule)
	* [ignore_ruleset](#ignore_ruleset)
	* [mode](#mode)
	* [nameservers] (#nameservers)
	* [process_multipart_body](#process_multipart_body)
	* [req_tid_header](#req_tid_header)
	* [res_body_max_size](#res_body_max_size)
	* [res_body_mime_types](#res_body_mime_types)
	* [res_tid_header](#res_tid_header)
	* [score_threshold](#score_threshold)
	* [storage_backend](#storage_backend)
	* [storage_keepalive](#storage_keepalive)
	* [storage_keepalive_timeout](*storage_keepalive_timeout)
	* [storage_keepalive_pool_size](*storage_keepalive_pool_size)
	* [storage_memcached_host](#storage_memcached_host)
	* [storage_memcached_port](#storage_memcached_port)
	* [storage_redis_host](#storage_redis_host)
	* [storage_redis_port](#storage_redis_port)
	* [storage_zone](#storage_zone)
* [Phase Handling](#phase-handling)
* [Included Rulesets](#included-rulesets)
* [Rule Definitions](#rule-definitions)
* [Notes](#notes)
	* [Community](#community)
	* [Pull Requests](#pull-requests)
* [Roadmap](#roadmap)
* [Limitations](#limitations)
* [License](#license)
* [Bugs](#bugs)
* [See Also](#see-also)

##Status

[![Build Status](https://travis-ci.org/p0pr0ck5/lua-resty-waf.svg?branch=development)](https://travis-ci.org/p0pr0ck5/lua-resty-waf)
[![Codewake](https://www.codewake.com/badges/ask_question.svg)](https://www.codewake.com/p/lua-resty-waf)

lua-resty-waf is currently in active development. New bugs and questions opened in the issue tracker will be answered within a day or two, and performance impacting / security related issues will be patched with high priority. Larger feature sets and enhancements will be added when development resources are available (see the [Roadmap](#roadmap) section for an outline of planned features).

lua-resty-waf is compatible with the master branch of `lua-resty-core`. The bundled version of `lua-resty-core` available in recent releases of OpenResty (>= 1.9.7.4) is compatible with lua-resty-waf; versions bundled with older OpenResty bundles are not, so users wanting to leverage `resty.core` will either need to replace the local version with the one available from the [GitHub project](https://github.com/openresty/lua-resty-core), or patch the module based off [this commit](https://github.com/openresty/lua-resty-core/commit/40445b12c0359eb82702f0097cd65948c245b6a4).

##Description

lua-resty-waf is a reverse proxy WAF built using the OpenResty stack. It uses the Nginx Lua API to analyze HTTP request information and process against a flexible rule structure. lua-resty-waf is distributed with a ruleset that mimics the ModSecurity CRS, as well as a few custom rules built during initial development and testing, and a small virtual patchset for emerging threats. Additionally, lua-resty-waf is distributed with tooling to automatically translate existing ModSecurity rules, allowing users to extend lua-resty-waf implementation without the need to learn a new rule syntax.

lua-resty-waf was initially developed by Robert Paprocki for his Master's thesis at Western Governor's University.

##Requirements

lua-resty-waf requires several third-party resty lua modules, though these are all packaged with lua-resty-waf, and thus do not need to be installed separately. It is recommended to install lua-resty-waf on a system running the OpenResty software bundle; lua-resty-waf has not been tested on platforms built using separate Nginx source and Nginx Lua module packages.

For optimal regex compilation performance, it is recommended to build Nginx/OpenResty with a version of PCRE that supports JIT compilation. If your OS does not provide this, you can build JIT-capable PCRE directly into your Nginx/OpenResty build. To do this, reference the path to the PCRE source in the `--with-pcre` configure flag. For example:

```sh
	# ./configure --with-pcre=/path/to/pcre/source --with-pcre-jit
```

You can download the PCRE source from the [PCRE website](http://www.pcre.org/). See also this [blog post](https://www.cryptobells.com/building-openresty-with-pcre-jit/) for a step-by-step walkthrough on building OpenResty with a JIT-enabled PCRE library.

##Performance

lua-resty-waf was designed with efficiency and scalability in mind. It leverages Nginx's asynchronous processing model and an efficient design to process each transaction as quickly as possible. Load testing has show that deployments implementing all provided rulesets, which are designed to mimic the logic behind the ModSecurity CRS, process transactions in roughly 300-500 microseconds per request; this equals the performance advertised by [Cloudflare's WAF](https://www.cloudflare.com/waf). Tests were run on a reasonable hardware stack (E3-1230 CPU, 32 GB RAM, 2 x 840 EVO in RAID 0), maxing at roughly 15,000 requests per second. See [this blog post](http://www.cryptobells.com/freewaf-a-high-performance-scalable-open-web-firewall) for more information.

lua-resty-waf workload is almost exclusively CPU bound. Memory footprint in the Lua VM (excluding persistent storage backed by `lua-shared-dict`) is roughly 2MB.

##Installation

A simple Makefile is provided. Simply run `make install`:

```
	# make install
```

Alternatively, install via Luarocks:

```
	# luarocks install lua-resty-waf
```

Note that by default lua-resty-waf runs in SIMULATE mode, to prevent immediately affecting an application; users who wish to enable rule actions must explicitly set the operational mode to ACTIVE.

##Synopsis

```lua
	http {
		-- include lua_resty_waf in the appropriate paths
		lua_package_path '/usr/local/openresty/lualib/lua_resty_waf/?.lua;;';
		lua_package_cpath '/usr/local/openresty/lualib/lua_resty_waf/?.lua;;';

		init_by_lua '
			-- use resty.core for performance improvement, see the status note above
			require "resty.core"

			-- require the base module
			local lua_resty_waf = require "waf"

			-- define options that will be inherited across all scopes
			lua_resty_waf.default_option("debug", true)
			lua_resty_waf.default_option("mode", "ACTIVE")

			-- this may be desirable for low-traffic or testing sites
			-- by default, event logs are not written until the buffer is full
			-- for testing, flush the log buffer every 5 seconds
			lua_resty_waf.default_option("event_log_periodic_flush", 5)

			-- perform some preloading and optimization
			lua_resty_waf.init()
		';
	}

	server {
		location / {
			access_by_lua '
				local lua_resty_waf = require "waf"

				local waf = lua_resty_waf:new()

				-- default options can be overridden
				waf:set_option("debug", false)

				-- run the firewall
				waf:exec()
			';

			header_filter_by_lua '
				local lua_resty_waf = require "waf"

				-- note that options set in previous handlers (in the same scope)
				-- do not need to be set again
				local waf = lua_resty_waf:new()

				waf:exec()
			';

			body_filter_by_lua '
				local lua_resty_waf = require "waf"

				local waf = lua_resty_waf:new()

				waf:exec()
			';

			log_by_lua '
				local lua_resty_waf = require "waf"

				local waf = lua_resty_waf:new()

				-- write out any event log entries to the
				-- configured target, if applicable
				waf:write_log_events()
			';
		}
	}
```

##Public Functions

###lua_resty_waf.default_option()

Define default values for configuration options that will be inherited across all scopes. This is useful when you are using lua-resty-waf in many different scopes (i.e. many server blocks, locations, etc.), and don't want to have to make the same call to `set_option` many times. You do not have to call this function if you are not changing the value of the option from what is defined as the default.

```lua
	http {
		init_by_lua '
			local lua_resty_waf = require "waf"

			lua_resty_waf.default_option("debug", true)

			-- this would be a useless operation since it does not change the default
			lua_resty_waf.default_option("debug_log_level", ngx.INFO)
		';
	}
```

###lua-resty-waf.init()

Perform some pre-computation of rules and rulesets, based on what's been made available via the default distributed rulesets and those added or ignored via `default_option`. It's recommended, but not required, to call this function (not doing so will result in a small performance penalty). This function should be called after any lua-resty-waf function call in `init_by_lua`, and should never be called outside this scope.

*Example*:

```lua
	http {
		init_by_lua '
			local lua_resty_waf = require "waf"

			-- set default options...

			lua_resty_waf.init()
		';
	}
```

##Public Methods

###lua-resty-waf:new()

Instantiate a new instance of lua-resty-waf. You must call this in every request handler phase you wish to run lua-resty-waf, and use the return result to call further object methods.

*Example*:

```lua
	location / {
		access_by_lua '
			local lua_resty_waf = require "waf"

			local waf = lua_resty_waf:new()
		';
	}
```

###lua-resty-waf:set_option()

Configure an option on a per-scope basis. You should only do this if you are overriding a default value in this scope (e.g. it would be useless to use this to define the same configurable everywhere).

*Example*:

```lua
	location / {
		access_by_lua '
			local lua_resty_waf = require "waf"

			local waf = lua_resty_waf:new()

			-- enable debug logging only for this scope
			waf:set_option("debug", true)
		';
	}
```

###lua-resty-waf:reset_option()

Set the given option to its documented default, regardless of whatever value was assigned via `default_option`. This is most useful for options that are more complex than boolean or integer values.

*Example*:

```lua
	http {
		init_by_lua '
			local lua_resty_waf = require "waf"

			lua_resty_waf.default_option("allowed_content_types", "text/json")
		';
	}

	[...snip...]

	location / {
		access_by_lua '
			local lua_resty_waf = require "waf"

			local waf = lua_resty_waf:new()

			-- reset the value to its documented default
			waf:reset_option("allowed_content_types")
		';
	}
```

###lua-resty-waf:write_log_events()

Write any audit log entries that were generated from the transaction. This should be called in the `log_by_lua` handler.

*Example*:

```lua
	location / {
		log_by_lua '
			local lua_resty_waf = require "waf"

			local waf = lua_resty_waf:new()

			-- write out any event log entries to the
			-- configured target, if applicable
			waf:write_log_events()
		';
	}
```

##Options

Module options can be configured using the `default_option` and `set_option` functions. Use `default_option` when in the `init_by_lua` handler, and without calling `lua-resty-waf:new()`, to set default values that will be inherited across all scopes. These values (or options that were not modified by `default_option` can be further adjusted on a per-scope basis via `set_option`. Additionally, scope-level options can be re-adjusted back to the documented defaults via the `reset_option` method. This will set the given option to its documented default, overriding the default set by the `default_option` function.

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
			waf:set_option("add_ruleset", 50000)
		';
	}
```

Multiple rulesets may be added by passing a table of values to `set_option`. Note that ruleset names are sorted before processing. Rulesets are processed in a low-to-high sorted order.

###add_ruleset_string

*Default*: none

Adds an additional ruleset to be used during processing. This allows users to implement custom rulesets without stomping over the included rules directory. Rulesets are defined inline as a Lua string, in the form of a translated ruleset JSON structure.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("add_ruleset_string", "70000", [=[{"access":[{"action":"DENY","id":73,"operator":"REGEX","opts":{},"pattern":"foo","vars":[{"parse":{"values":1},"type":"REQUEST_ARGS"}]}],"body_filter":[],"header_filter":[]}]=])
		';
	}
```

Note that ruleset names are sorted before processing, and must be given as strings. Rulesets are processed in a low-to-high sorted order.

###allow_unknown_content_types

*Default*: false

Instructs lua-resty-waf to continue processing the request when a Content-Type header has been sent that is not in the `allowed_content_types` table. Such requests will not have their request body processed by lua-resty-waf (the `REQUEST_BODY` collection will be nil). In this manner, users do not need to explicitly whitelist all possible Content-Type headers they may encounter.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("allow_unknown_content_types", true)
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
			waf:set_option("allowed_content_types", "text/xml")

			-- defines multiple allowed Content-Type values
			waf:set_option("allowed_content_types", { "text/html", "text/json", "application/json" })
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
			waf:set_option("debug", true)
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
			waf:set_option("debug_log_level", ngx.DEBUG)
		';
	}
```

###deny_status

*Default*: ngx.HTTP_FORBIDDEN

Sets the status to use when denying requests.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("deny_status", ngx.HTTP_NOT_FOUND)
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
			waf:set_option("disable_pcre_optimization", true)
		';
	}
```

###event_log_altered_only

*Default*: true

Determines whether to write log entries for rule matches in a transaction that was not altered by lua-resty-waf. "Altered" is defined as lua-resty-waf acting on a rule whose action is `ACCEPT` or `DENY`. When this option is unset, lua-resty-waf will log rule matches even if the transaction was not altered. By default, lua-resty-waf will only write log entries for matches if the transaction was altered.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("event_log_altered_only", false)
		';
	}
```

Note that `mode` will not have an effect on determing whether a transaction is considered altered. That is, if a rule with a `DENY` action is matched, but lua-resty-waf is running in `SIMULATE` mode, the transaction will still be considered altered, and rule matches will be logged.

###event_log_buffer_size

*Default*: 4096

Defines the threshold size, in bytes, of the buffer to be used to hold event logs. The buffer will be flushed when this threshold is met.

*Example*:

```lua
	location / {
		access_by_lua '
			-- 8 KB event log message buffer
			waf:set_option("event_log_buffer_size", 8192)
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
			waf:set_option("event_log_level", ngx.WARN)
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
			waf:set_option("event_log_ngx_vars", "host")
			waf:set_option("event_log_ngx_vars", "request_id")
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
			waf:set_option("event_log_periodic_flush", 30)
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
			waf:set_option("event_log_request_arguments", true)
		';
	}
```

###event_log_request_body

*Default*: false

When set to true, the log entries contain the request body under the `request_body` key.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("event_log_request_arguments", true)
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
			waf:set_option("event_log_request_headers", true)
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

###event_log_ssl

*Default*: false

Enable SSL connections when logging via TCP/UDP.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("event_log_ssl", true)
		';
	}
```

###event_log_ssl_sni_host

*Default*: none

Set the SNI host for `lua-resty-logger-socket` connections.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("event_log_ssl_sni_host", "loghost.example.com")
		';
	}
```

###event_log_ssl_verify

*Default*: false

Enable certification verification for SSL connections when logging via TCP/UDP.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("event_log_ssl_verify", true)
		';
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
			waf:set_option("event_log_socket_proto", "tcp")
		';
	}
```

###event_log_target

*Default*: error

Defines the destination for event logs. lua-resty-waf currently supports logging to the error log, a separate file on the local file system, or a remote TCP or UDP server. In the latter two cases, event logs are buffered and flushed when a defined threshold is reached (see below for further options regarding event logging options).

*Example*:

```lua
	location / {
		access_by_lua '
			-- send event logs to the server's error_log location (default)
			waf:set_option("event_log_target", "error")

			-- send event logs to a local file on disk
			waf:set_option("event_log_target", "file")

			-- send event logs to a remote server
			waf:set_option("event_log_target", "socket")
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
			waf:set_option("event_log_target_host", "10.10.10.10")
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
			waf:set_option("event_log_target_path", "/var/log/lua-resty-waf/event.log")
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
			waf:set_option("event_log_target_port", 9001)
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
			waf:set_option("event_log_verbosity", 1)

			-- the rule description will be written in addition to existing data
			waf:set_option("event_log_verbosity", 2)

			-- the rule description, options and action will be written in addition to existing data
			waf:set_option("event_log_verbosity", 3)

			-- the entire rule definition, including the match pattern, will be written in addition to existing data
			-- note that for some rule definitions, such as the XSS and SQLi rulesets, this pattern can be large
			waf:set_option("event_log_verbosity", 4)
		';
	}
```

###hook_action

*Default*: none

Override the functionality of actions taken when a rule is matched. See the example for more details

*Example*:

```lua

		location / {
			access_by_lua '
				local deny_override = function(waf, ctx)
					ngx.log(ngx.INFO, "Overriding DENY action")
					ngx.status = 404
				end

				-- override the DENY action with the function defined above
				waf:set_option("hook_action", "DENY", deny_override)
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
			waf:set_option("ignore_rule", 40294)
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
			waf:set_option("ignore_ruleset", 40000)
		';
	}
```

###mode

*Default*: SIMULATE

Sets the operational mode of the module. Options are ACTIVE, INACTIVE, and SIMULATE. In ACTIVE mode, rule matches are logged and actions are run. In SIMULATE mode, lua-resty-waf loops through each enabled rule and logs rule matches, but does not complete the action specified in a given run. INACTIVE mode prevents the module from running.

By default, SIMULATE is selected if a mode is not explicitly set; this requires new users to actively implement blocking by setting the mode to ACTIVE.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("mode", "ACTIVE")
		';
	}
```

###nameservers

*Default*: none

Sets the DNS resolver(s) to be used for RBL lookups. Currently only UDP/53 traffic is supported. This option must be defined as a numeric address, not a hostname. If this option is not defined, all RBL lookup rules will return false.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("nameservers", "10.10.10.10")
		';
	}
```

###process_multipart_body

*Default* true

Enable processing of multipart/form-data request bodies (when present), using the `lua-resty-upload` module. In the future, lua-resty-waf may use this processing to perform stricter checking of upload bodies; for now this module performs only minimal sanity checks on the request body, and will not log an event if the request body is invalid. Disable this option if you do not need this checking, or if bugs in the upstream module are causing problems with HTTP uploads.

*Example*:

```lua
	location / {
		access_by_lua '
			-- disable processing of multipart/form-data requests
			-- note that the request body will still be sent to the upstream
			waf:set_option("process_multipart_body", false)
		';
	}
```

###req_tid_header

*Default*: false

Set an HTTP header `X-Lua-Resty-WAF-ID` in the upstream request, with the value as the transaction ID. This ID will correlate with the transaction ID present in the debug logs (if set). This can be useful for request tracking or debug purposes.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("req_tid_header", true)
		';
	}
```

###res_body_max_size

*Default*: 1048576 (1 MB)

Defines the content length threshold beyond which response bodies will not be processed. This size of the response body is determined by the Content-Length response header. If this header does not exist in the response, the response body will never be processed.

*Example*:

```lua
	location / {
		access_by_lua '
			-- increase the max response size to 2 MB
			waf:set_option("res_body_max_size", 1024 * 1024 * 2)
		';
	}
```
Note that by nature, it is required to buffer the entire response body in order to properly use the response as a collection, so increasing this number significantly is not recommended without justification (and ample server resources).

###res_body_mime_types

*Default*: "text/plain", "text/html"

Defines the MIME types with which lua-resty-waf will process the response body. This value is determined by the Content-Type header. If this header does not exist, or the response type is not in this list, the response body will not be processed. Setting this option will add the given MIME type to the existing defaults of `text/plain` and `text/html`.

*Example*:

```lua
	location / {
		access_by_lua '
			-- mime types that will be processed are now text/plain, text/html, and text/json
			waf:set_option("res_body_mime_types", "text/json")
		';
	}
```

Multiple MIME types can be added by passing a table of types to `set_option`.

###res_tid_header

*Default*: false

Set an HTTP header `X-Lua-Resty-WAF-ID` in the downstream response, with the value as the transaction ID. This ID will correlate with the transaction ID present in the debug logs (if set). This can be useful for request tracking or debug purposes.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("res_tid_header", true)
		';
	}
```

###score_threshold

*Default*: 5

Sets the threshold for anomaly scoring. When the threshold is reached, lua-resty-waf will deny the request.

*Example*:

```lua
	location / {
		access_by_lua '
			waf:set_option("score_threshold", 10)
		';
	}
```

###storage_backend

*Default*: dict

Define an engine to use for persistent variable storage. Current available options are *dict* (ngx_lua shared memory zone), *memcached*, amd *redis*.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_backend", "memcached")
		';
	}
```

###storage_keepalive

*Default*: true

Enable or disable TCP keepalive for connections to remote persistent storage hosts.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_keepalive", false)
		';
	}
```

###storage_keepalive_timeout

*Default*: 10000

Configure (in milliseconds) the timeout for the cosocket keepalive pool for remote persistent storage hosts.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_keepalive_timeout", 30000)
		';
	}
```

###storage_keepalive_pool_size

*Default*: 100

Configure the pool size for the cosocket keepalive pool for remote persistent storage hosts.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_keepalive_pool_size", 50)
		';
	}
```

###storage_memcached_host

*Default*: 127.0.0.1

Define a host to use when using memcached as a persistent variable storage engine.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_host", "10.10.10.10")
		';
	}
```

###storage_memcached_port

*Default*: 11211

Define a port to use when using memcached as a persistent variable storage engine.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_port", 11221)
		';
	}
```

###storage_redis_host

*Default*: 127.0.0.1

Define a host to use when using redis as a persistent variable storage engine.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_host", "10.10.10.10")
		';
	}
```

###storage_redis_port

*Default*: 6379

Define a port to use when using redis as a persistent variable storage engine.

*Example*:

```lua
	location / {
		acccess_by_lua '
			waf:set_option("storage_port", 6397)
		';
	}
```

###storage_zone

*Default*: none

Defines the `lua_shared_dict` that will be used to hold persistent storage data. This zone must be defined in the `http{}` block of the configuration.

*Example*:_

```lua
	http {
		-- define a 64M shared memory zone to hold persistent storage data
		lua_shared_dict persistent_storage 64m;
	}

	location / {
		access_by_lua '
			waf:set_option("storage_zone", "persistent_storage")
		';
	}
```

Multiple shared zones can be defined and used, though only one zone can be defined per configuration location. If a zone becomes full and the shared dictionary interface cannot add additional keys, the following will be entered into the error log:

`Error adding key to persistent storage, increase the size of the lua_shared_dict`

##Phase Handling

lua-resty-waf is designed to run in multiple phases of the request lifecycle. Rules can be processed in the following phases:

* **access**: Request information, such as URI, request headers, URI args, and request body are available in this phase.
* **header_filter**: Response headers and HTTP status are available in this phase.
* **body_filter**: Response body is available in this phase.

These phases correspond to their appropriate Nginx lua handlers (`access_by_lua`, `header_filter_by_lua`, and `body_filter_by_lua`, respectively). Note that running lua-resty-waf in a lua phase handler not in this list will lead to broken behavior. All data available in an earlier phase is available in a later phase. That is, data available in the `access` phase is also available in the `header_filter` and `body_filter` phases, but not vice versa.

Additionally, it is required to call `write_log_events` in a `log_by_lua` handler. lua-resty-waf is not designed to process rules in this phase; logging rules late in the request allows all rules to be coalesced into a single entry per request. See the synopsis above for example syntax.

##Included Rulesets

lua-resty-waf is distributed with a number of rulesets that are designed to mimic the functionality of the ModSecurity CRS. For reference, these rulesets are listed here:

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

lua-resty-waf parses rules definitions from JSON blobs stored on-disk. Rules are grouped based on purpose and severity, defined as a ruleset. The included rulesets were created to mimic some functionality of the ModSecurity CRS, particularly the `base_rules` definitions. Additionally, the included `modsec2lua-resty-waf.pl` script can be used to translate additional or custom rulesets to a lua-resty-waf-compatible JSON blob.

Note that there are several limitations in the translation script, with respect to unsupported actions, collections, and operators. Please see [this wiki page](https://github.com/p0pr0ck5/lua-resty-waf/wiki/Known-ModSecurity-Translation-Limitations) for an up-to-date list of known incompatibilities.

##Notes

###Community

There is a Freenode IRC channel `#lua-resty-waf`. Travis CI sends notifications here; feel free to ask questions/leave comments in this channel as well.

Additionally, Q/A is available on CodeWake:

[![Codewake](https://www.codewake.com/badges/ask_question.svg)](https://www.codewake.com/p/lua-resty-waf)

###Pull Requests

Please target all pull requests towards the development branch, or a feature branch if the PR is a significant change. Commits to master should only come in the form of documentation updates or other changes that have no impact of the module itself (and can be cleanly merged into development).

##Roadmap

* **Expanded virtual patch ruleset**: Increase coverage of emerging threats.
* **Expanded integration/acceptance testing**: Increase coverage of common threats and usage scenarios.
* **Expanded ModSecurity syntax translations**: Support more operators, variables, and actions.
* **Common application profiles**: Tuned rulesets for common CMS/applications.
* **Support multiple socket/file logger targets**: Likely requires forking the lua-resty-logger-socket project.

##Limitations

lua-resty-waf is undergoing continual development and improvement, and as such, may be limited in its functionality and performance. Currently known limitations can be found within the GitHub issue tracker for this repo.

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
- My personal blog for updates and notes on lua-resty-waf development: <http://www.cryptobells.com/tag/lua-resty-waf/>
