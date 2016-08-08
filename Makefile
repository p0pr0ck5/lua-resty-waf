OPENRESTY_PREFIX ?= /usr/local/openresty
LUA_LIB_DIR      ?= $(OPENRESTY_PREFIX)/lualib
INSTALL          ?= ln -s
INSTALL_HARD      = cp -r
PWD               = `pwd`

LIBS    = cookie.lua iputils.lua logger libinjection.lua waf waf.lua
SO_LIBS = libac.so libinjection.so
RULES   = rules

.PHONY: all test install clean

all: ;

clean:
	cd $(LUA_LIB_DIR) && rm -rf $(RULES) && rm $(SO_LIBS) && cd resty/ && rm -rf $(LIBS)

test:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/

install: all
	$(INSTALL) -d $(LUA_LIB_DIR)/resty
	$(INSTALL) -d $(LUA_LIB_DIR)/resty/logger
	$(INSTALL) -d $(LUA_LIB_DIR)/resty/waf
	$(INSTALL) $(PWD)/lib/resty/*.lua $(LUA_LIB_DIR)/resty/
	$(INSTALL) $(PWD)/lib/resty/logger/*.lua $(LUA_LIB_DIR)/resty/logger/
	$(INSTALL) $(PWD)/lib/resty/waf/*.lua $(LUA_LIB_DIR)/resty/waf/
	$(INSTALL) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL) $(PWD)/rules/* $(LUA_LIB_DIR)

install-hard: all
	$(INSTALL_HARD) $(PWD)/lib/resty/* $(LUA_LIB_DIR)/resty/
	$(INSTALL_HARD) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL_HARD) $(PWD)/rules/ $(LUA_LIB_DIR)
