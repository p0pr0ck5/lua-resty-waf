##Name

FreeWAF - Non-blocking WAF built on the OpenResty stack

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

Note that by default FreeWAF runs in DEBUG mode, to prevent immediately affecting an application; users who wish to enable rule actions must explicitly set the operational mode to ACTIVE.

##Synopsis

```lua
	http {
		init_by_lua '
			fw = require "FreeWAF.fw" --global reference to the FreeWAF module
			fw.init() --init sets up the module option defaults

			-- setup FreeWAF to deny requests that match a rule
			fw.set_option("mode", "ACTIVE")

			-- each of these is optional
			fw.set_option("whitelist", "127.0.0.1")
			fw.set_option("blacklist", "1.2.3.4")
			fw.set_option("ignore_rule", 42094)
		';
	}

	server {
		# FreeWAF works in Nginxs access phase, so any content delivery mechanism (e.g. HTTP proxy, fcgi proxy, direct static content) can be used

		access_by_lua '
			fw.exec()
		';
	}
```

##Options

Several options can be configured during the init phase using the `set_option` function, including setting the operational mode, configuring white and blacklists, ignoring specific rules, and configuring custom rulesets (though this feature currently needs work, as we refine the ruleset language and build a more human-readable syntax).

###mode

*Default*: DEBUG

Sets the operational mode of the module. Options are ACTIVE, INACTIVE, and DEBUG. In ACTIVE mode, rule matches are logged and actions are run. In DEBUG mode, FreeWAF loops through each enabled rule and logs rule matches, but does not complete the action specified in a given run. INACTIVE mode prevents the module from running.

By default, DEBUG is selected if not explicit mode is set; this requires new users to actively implement blocking by setting the mode to ACTIVE.

*Example*:

```lua
	http {
		init_by_lua '
			fw = require "FreeWAF.fw"
			fw.init()
			fw.set_option("mode", "ACTIVE")
		';
	}
```

###whitelist

*Default*: none

Adds an address to the module whitelist. Whitelisted addresses will not have any rules applied to their requests, and will be immediately passed through the module.

*Example*:

```lua
	http {
		init_by_lua '
			fw = require "FreeWAF.fw"
			fw.init()
			fw.set_option("whitelist", "1.2.3.4")
		';
	}
```

###blacklist

*Default*: none

Adds an address to the module blacklist. Blacklisted addresses will not have any rules appled to their requests, and will be immediately rejected by the module (Nginx will return a 403 to the client)

*Example*:

```lua
	http {
		init_by_lua '
			fw = require "FreeWAF.fw"
			fw.init()
			fw.set_option("blacklist", "5.6.7.8")
		';
	}
```

Note that blacklists are processed _after_ whitelists, so an address that is whitelisted and blacklisted will always be processed as a whitelisted address.

###ignore_rule

*Default*: none

Instructs the module to ignore a specified rule ID. Note that FreeWAF uses Lua table to track values, and for efficiency stores the configured value as a table key, so it is not recommended to directly edit the `_ignored_rules` table in the module, and instead use this function interface.

*Example*:

```lua
	http {
		init_by_lua '
			fw = require "FreeWAF.fw"
			fw.init()
			fw.set_option("ignore_rule", 40294)
		';
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
