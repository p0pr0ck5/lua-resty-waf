##Name

FreeWAF - Non-blocking WAF built on the OpenResty stack

##Status

FreeWAF is in active development. It is currently being rewritten, and shouldn't be used in any production environment at this point. This repository exists for historical purposes.

##Description

FreeWAF is a reverse proxy WAF built using the OpenResty stack. It uses the Nginx Lua API to analyze HTTP request information and process against a flexible rule structure. FreeWAF is distributed with a ruleset that mimics the ModSecurity CRS, as well as a few custom rules built during initial development and testing.

FreeWAF was initially developed by Robert Paprocki for his Master's thesis at Western Governor's University.

##Installation

Clone the FreeWAF repo into Nginx's Lua package path. See the included Nginx configuration file for an example `access_by_lua` directive.

##TODO

This project needs a complete overhaul, which is current in progress. Points of interest are:

- Configuration option delivery
- Rule syntax rewrite
- Transaction parse memoization
- Behavioral analysis integration

Check out the `waf_refactoring` branch for more info.

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
- javdipdave's QuickDefence project, a separate implementation of an Nginx/Lua WAF <https://github.com/jaydipdave/quickdefencewaf>
