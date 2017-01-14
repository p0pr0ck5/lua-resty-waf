#!/bin/bash

if [ "$1" == "clean" ]; then
	sed -i -r "s/([[:blank:]]+)if self\._debug == true then ngx\.log\(.*?'\] ', (.*)\) end/\1--_LOG_\2/g" ./lib/resty/waf.lua
	find ./lib/resty/waf/ -type f -exec sed -i -r "s/([[:blank:]]+)if waf\._debug == true then ngx\.log\(.*?'\] ', (.*)\) end/\1--_LOG_\2/g" {} \;
else
	sed -i -r "s/--_LOG_(.*)/if self._debug == true then ngx.log\(self._debug_log_level, '[', self.transaction_id, '] ', \1\) end/g" ./lib/resty/waf.lua
	find ./lib/resty/waf/ -type f -exec sed -i -r "s/--_LOG_(.*)/if waf._debug == true then ngx.log\(waf._debug_log_level, '[', waf.transaction_id, '] ', \1\) end/g" {} \;
fi
