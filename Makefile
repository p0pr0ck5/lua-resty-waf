OPENRESTY_PREFIX ?= /usr/local/openresty
LUA_LIB_DIR      ?= $(OPENRESTY_PREFIX)/lualib
INSTALL          ?= ln -s
INSTALL_HARD      = cp -r
PWD               = `pwd`

LIBS    = cookie.lua iputils.lua logger libinjection.lua waf waf.lua
SO_LIBS = libac.so libinjection.so
RULES   = rules

.PHONY: all test install clean test-unit test-acceptance test-regression test-translate

all: ;

clean:
	cd $(LUA_LIB_DIR) && rm -rf $(RULES) && rm $(SO_LIBS) && cd resty/ && rm -rf $(LIBS)

test-unit:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/unit

test-acceptance:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/acceptance

test-regression:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/regression

test-translate:
	prove -r ./t/translate/

test: test-unit test-acceptance test-regression test-translate

install: all
	$(INSTALL) $(PWD)/lib/resty/* $(LUA_LIB_DIR)/resty/
	$(INSTALL) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL) $(PWD)/rules/ $(LUA_LIB_DIR)

install-hard: all
	$(INSTALL_HARD) $(PWD)/lib/resty/* $(LUA_LIB_DIR)/resty/
	$(INSTALL_HARD) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL_HARD) $(PWD)/rules/ $(LUA_LIB_DIR)
