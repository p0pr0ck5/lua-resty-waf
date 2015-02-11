##Name

FreeWAF - High-performance WAF built on the OpenResty stack

##Status

FreeWAF is in active development. It is currently in beta status, with new features being added regularly, though the existing platform is stable.

##Description

FreeWAF is a reverse proxy WAF built using the OpenResty stack. It uses the Nginx Lua API to analyze HTTP request information and process against a flexible rule structure. FreeWAF is distributed with a ruleset that mimics the ModSecurity CRS, as well as a few custom rules built during initial development and testing.

FreeWAF was initially developed by Robert Paprocki for his Master's thesis at Western Governor's University.

##Requirements

FreeWAF requires several third-party resty lua modules, though these are all packaged with FreeWAF, and thus do not need to be installed separately. It is recommended to install FreeWAF on a system running the OpenResty software bundle; FreeWAF has not been tested on platforms built using separate Nginx source and Nginx Lua module packages.

For optimal regex compilation performance, it is recommended to build Nginx/OpenResty with a version of PCRE that supports JIT compilation. If your OS does not provide this, you can build JIT-capable PCRE directly into your Nginx/OpenResty build. To do this, reference the path to the PCRE source in the `--with-pcre` configure flag. For example:

```sh
	# ./configure --with-pcre=/path/to/pcre/source --with-pcre-jit
```

You can download the PCRE source from the [PCRE website](http://www.pcre.org/).

##Performance

FreeWAF was designed with efficiency and scalability in mind. It leverages Nginx's asynchronous processing model and an efficient design to process each transaction as quickly as possible. Early testing has show that deployments implementing all provided rulesets, which are designed to mimic the logic behind the ModSecurity CRS, process transactions in roughly 300-500 microseconds per request; this equals the performance advertised by [Cloudflare's WAF](https://www.cloudflare.com/waf). Tests were run on a reasonable hardware stack (E3-1230 CPU, 32 GB RAM, 2 x 840 EVO in RAID 0), maxing at roughly 15,000 requests per second. See [this blog post](http://www.cryptobells.com/freewaf-a-high-performance-scalable-open-web-firewall) for more information.

##Installation

Clone the FreeWAF repo into Nginx/OpenResty's Lua package path. Module setup and configuration is detailed in the synopsis.

Note that by default FreeWAF runs in SIMULATE mode, to prevent immediately affecting an application; users who wish to enable rule actions must explicitly set the operational mode to ACTIVE.

##Synopsis

```lua
	http {
		-- include FreeWAF in the lua_package_path
		lua_package_path '/usr/local/openresty/lualib/FreeWAF/?.lua;;';
	}

	server {
		location / {
			access_by_lua '
				FreeWAF = require "FreeWAF.fw"

				-- instantiate a new instance of the module
				local fw = FreeWAF:new()

				-- setup FreeWAF to deny requests that match a rule
				fw:set_option("mode", "ACTIVE")

				-- each of these is optional, see the options documentation for more details
				fw:set_option("whitelist", "127.0.0.1")
				fw:set_option("blacklist", "1.2.3.4")
				fw:set_option("ignore_rule", 42094)

				-- run the firewall
				fw:exec()
			';
		}
	}
```

##Options

Several options can be configured during the init phase using the `set_option` function, including setting the operational mode, configuring white and blacklists, ignoring specific rules, and configuring custom rulesets (though this feature currently needs work, as we refine the ruleset language and build a more human-readable syntax).

###mode

*Default*: SIMULATE

Sets the operational mode of the module. Options are ACTIVE, INACTIVE, and SIMULATE. In ACTIVE mode, rule matches are logged and actions are run. In SIMULATE mode, FreeWAF loops through each enabled rule and logs rule matches, but does not complete the action specified in a given run. INACTIVE mode prevents the module from running.

By default, SIMULATE is selected if mode is not explicitly set; this requires new users to actively implement blocking by setting the mode to ACTIVE.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("mode", "ACTIVE")
		';
	}
```

###whitelist

*Default*: none

Adds an address to the module whitelist. Whitelisted addresses will not have any rules applied to their requests, and will be immediately passed through the module.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("whitlist", "127.0.0.1")
		';
	}
```

Multiple addresses can be whitelisted by passing a table of addresses to `set_option`.

###blacklist

*Default*: none

Adds an address to the module blacklist. Blacklisted addresses will not have any rules appled to their requests, and will be immediately rejected by the module (Nginx will return a 403 to the client)

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("blacklist", "5.6.7.8")
		';
	}
```

Multiple addresses can be whitelisted by passing a table of addresses to `set_option`. Note that blacklists are processed _after_ whitelists, so an address that is whitelisted and blacklisted will always be processed as a whitelisted address.

###ignore_rule

*Default*: none

Instructs the module to ignore a specified rule ID. Note that FreeWAF uses Lua table to track values, and for efficiency stores the configured value as a table key, so it is not recommended to directly edit the `_ignored_rules` table in the module, and instead use this function interface.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("ignore_rule", 40294)
		';
	}
```

###ignore_ruleset

*Default*: none

Instructs the module to ignore an entire ruleset. This can be useful when some rulesets (such as the SQLi or XSS CRS rulesets) are too prone to false positives, or aren't applicable to your web app.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("ignore_ruleset", 40000)
		';
	}
```

###score_threshold

*Default*: 5

Sets the threshold for anomaly scoring. When the threshold is reached, FreeWAF will deny the transaction.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("score_threshold", 10)
		';
	}
```

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

###event_log_target

*Default*: error

Defines the destination for event logs. FreeWAF currently supports logging to the error log, a separate file on the local file system, or a remote UDP server. In the latter two cases, event logs are buffered and flushed when a defined threshold is reached (see below for further options regarding event logging options).

*Example*:

```lua
	location / {
		access_by_lua '
			-- send event logs to the server's error_log location (default)
			fw:set_option("event_log_target", "error")

			-- send event logs to a local file on disk
			fw:set_option("event_log_target", "file")

			-- send event logs to a remote UDP server
			fw:set_option("event_log_target", "socket")
		';
	}
```

###event_log_target_host

*Default*: none

Defines the target server for event logs that target a UDP server.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_target_host", "10.10.10.10")
		';
	}
```

###event_log_target_port

*Default*: none

Defines the target port for event logs that target a UDP server.

*Example*:

```lua
	location / {
		access_by_lua '
			fw:set_option("event_log_target_port", 9001)
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


##Rule Definitions

FreeWAF uses Lua tables to define its rules. Rules are grouped based on purpose and severity, defined as a ruleset. The included rulesets were created to mimic the functionality of the ModSecurity CRS. Each rule requires the following elements:

###id

A unique integer use to define each rule. By convention, the first two digits in a rule match those of its parent ruleset.

###description

A string that describes the purpose of the rule. This is purely descriptive.

###action

An enum (currently implemented as a string) that defines how the rule processor will act if a rule is a positive match. See the section on rule actions for available options.


###opts

A table that defines options specific to rule. The following options are currently supported:

* **chainchild**: Defines a rule that is part of a rule chain.
* **chainend**: Defines the last rule in the rule chain.
* **nolog**: Do not create a log entry if a rule match occurs. This is most commonly used in rule chains, with rules that have the CHAIN action (to avoid unnecessarily large quantities of log entries).
* **score**: Defines the score for a rule with the SCORE action. Must be a numeric value.
* **setvar**: Defines persistent storage data key, value and optional expiry time.
* **skipend**: Ends a skip chain. Note that the rule containing this option will be included as part of the skip chain, e.g. it will not be processed.
* **transform**: Defines how collection data is altered as an anti-evasion technique. Transform types include `base64_decode`, `base64_encode`, `html_decode`, and `lowercase`. Multiple transforms for a single collection can be specified by defining the `transform` option value as a table itself.

###var

A table that defines the rule's signature. Each var table must contain the following keys:

* **type**: Defines which collection of request data to parse; see the collections description for available options.
* **opts**: Defines options specific to the rule's signature. This value may be `nil`, or a table with a specific key/value definition. See the collections description for more detail regarding request data parsing.
* **pattern**: Defines the target match. This value can be a string, numeric value, table (for PM operators), or a regular expression. All regexes are case-insensitive.
* **operator**: Defines how to match the request against the pattern. See the section on operators for currently supported options.

##Actions

The following rule actions are currently supported:

* **ACCEPT**: Explicitly accepts the request, stopping all further rule processing and passing the request to the next phase handler.
* **CHAIN**: Sets a flag in the rule processor to proceed to the next rule in the rule chain. Rule chaining allows the rule processor to mimic logical AND operations; multiple rules can be chained together to define very specific signatures. If a rule in a rule chain does not match, all further rules in the chain are skipped.
* **DENY**: Explictly denies the request, stopping all further rule processing and exiting the phase handler with a 403 response (ngx.HTTP_FORBIDDEN).
* **IGNORE**: No action is taken, rule processing continues.
* **LOG**: A placeholder, as all rule matches that do not have the `nolog` opton set will be logged.
* **SCORE**: Increments the running request score by the score defined in the rule's option table.
* **SETVAR**: Set a persistent variable, using the `setvar` rule options table.
* **SKIP**: Skips processing of all further rules until a rule with the `skipend` flag is specified.

##Operators

The following pattern operators are currently supported:

* **EQUALS**: Matches using the `==` operator; comparison values can be any Lua primitive that can be compared directly (most commonly this is strings or integers).
* **EXISTS**: Searches for the existence of a given key in a table.
* **GREATER**: Matches using the `>` operator. Returns true if the collection data is greater than the pattern. Most commonly this is used for comparing running counters stored in persistent storage.
* **PM**: Performs an efficient pattern match using Aho-Corasick searching.
* **REGEX**: Matches using Perl compatible regular expressions.

All operators have a corresponding negated option, e.g., `NOT_EQUALS`, `NOT_EXISTS`, etc.

##Collections

FreeWAF's rule processor works on a basic principle of matching a `pattern` against a given `collection`. The following collections are currently supported:

* **COOKIES**: A table containing the values of the cookies sent in the request.
* **CLIENT**: The IP address of client.
* **HEADERS**: A table containing the request headers. Note that cookies are not included in this collection.
* **HEADER_NAMES**: A table containing the keys of the `HEADERS` table. Note that header names are automatically converted to a lowercase form.
* **HTTP_VERSION**: An integer representation of the HTTP version used in the request.
* **METHOD**: The HTTP method specified in the request.
* **REQUEST_ARGS**: A table containing the keys and values of all the arguments in the request, including query string arguments, POST arguments, and request cookies.
* **REQUEST_BODY**: A table containing the request body. This typically contains POST arguments.
* **REQUEST_LINE**: A string representation of the HTTP request line. This includes the request method, URI, and HTTP version. The collection is retrieved by splitting the HTTP request headers by newline, and returning the first element.
* **URI**: The request URI.
* **URI_ARGS**: A table containing the request query strings. 
* **USER_AGENT**: The value of the `User-Agent` header.
* **VAR**: The persistent storage variable collection.

Collections can be parsed based on the contents of a rule's `var.opts` table. This table must contain two keys: `key`, which defines how to parse the collection, and `value`, which determines what to parse out of the collection. The following values are supported for `key`:

* **all**: Retrieves both the keys and values of the collection. Note that this key does not require a `value` counterpart.
* **ignore**: Returns the collection minus the key (and its associated value) specified.
* **keys**: Retrieves the keys in the given collection. For example, the HEADER_NAMES collection is just a shortcut for the HEADERS collecton parsed by `{ key = "keys" }`. Note that this key does not require a `value` counterpart.
* **specific**: Retrieves a specific value from the collection. For example, the USER_AGENT collection is just a shortcut for the HEADERS collections parsed by `{ key = "specific", value = "user-agent" }`.
* **values**: Retrieves the values in the given collection. Note that this key does not require a `value` counterpart.

##Persistent Storage

FreeWAF supports storage of long-term (inter-request) data via the `lua_shared_dict` interface. Under the hood this uses Nginx's shared memory zone pattern, which uses a red-black tree. This means that persistent data storage operations, including search, insertion, and deletion, run in `O(log n)` time, so be wary of performance degredation if the size of the memory zone grows to tens or hundreds of thousands of keys. This data will persist over the lifetime of the Nginx master process, meaning that data will survive a server reload, e.g. a HUP, but will not survive a restart.

Persistent data is set with the `SETVAR` action. This requires the associated rule to return a positive match. Variable data is defined via the `setvar` rule option:

* **key**: String value to define the variable key. Portions of the key value can be dynamically defined using the syntax %{VAL}, where value is one of the dynamic options (currently, IP or URI).
* **value**: String, boolean, or integer value. If a key already exists, the value of the key will be overwritten with the given value. Integer values can be incremented by prepending a '+' (see the example below).
* **expire**: Optional integer to determine how long, in seconds, the key will live in persistent storage.

Storage keys can be dynamically defined based on several factors (currently the client IP and request URI) using a special syntax; this mimics the functionality of ModSecurity's `initcol` and `setvar` options. For example, a rule group to set a storage variable designed to track requests to a specific resource might look like this:

```lua
{   
	id = 12345,
	var = { 
		type = "URI",
		opts = nil,
		pattern = '/wp-login.php',
		operator = 'EQUALS'
	},
	opts = {},
	action = "CHAIN",
	description = "WP-Login brute force detection"
},
{
	id = 12346,
	var = {
		type = "METHOD",
		opts = nil,
		pattern = "POST",
		operator = "EQUALS"
	},
	opts = { setvar = { key = '%{IP}.%{URI}.hitcount', value = '+1', expire = 60 } },
	action = "SETVAR",
	description = "WP-Login brute force detection"
},
{
	id = 12347,
	var = {
		type = "VAR",
		opts = { value = '%{IP}.%{URI}.hitcount' },
		pattern = 5,
		operator = "GREATER"
	},
	opts = {},
	action = "DENY",
	description = "Deny more than 5 POST requests to wp-login.php in 60 seconds"
}
```

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

- The OpenResty project <http://openresty.org/>
- My personal blog for updates and notes on FreeWAF development <http://www.cryptobells.com/>
