OPENRESTY_PREFIX ?= /usr/local/openresty
LUA_LIB_DIR      ?= $(OPENRESTY_PREFIX)/lualib
INSTALL          ?= ln -s
PWD               = `pwd`

LIBS    = cookie.lua iputils.lua logger libinjection.lua waf waf.lua
SO_LIBS = libac.so libinjection.so
RULES   = rules

.PHONY: all test install clean

all: ;

clean:
	cd $(LUA_LIB_DIR) && rm $(RULES) && rm $(SO_LIBS) && cd resty/ && rm $(LIBS)

test:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/

install: all
	$(INSTALL) $(PWD)/lib/resty/* $(LUA_LIB_DIR)/resty/
	$(INSTALL) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL) $(PWD)/rules/ $(LUA_LIB_DIR)
