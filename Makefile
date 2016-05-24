OPENRESTY_PREFIX=/usr/local/openresty

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all test install

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf
	$(INSTALL) waf.lua $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/waf.lua
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc
	$(INSTALL) inc/*.* $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty
	$(INSTALL) inc/resty/*.lua $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty/
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty/dns
	$(INSTALL) inc/resty/dns/*.lua $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty/dns/
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty/logger
	$(INSTALL) inc/resty/logger/*.lua $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/inc/resty/logger/
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/lib
	$(INSTALL) lib/*.* $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/lib/
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/rules
	$(INSTALL) rules/*.json $(DESTDIR)$(LUA_LIB_DIR)/lua_resty_waf/rules/
	$(INSTALL) -d $(DESTDIR)/bin
	$(INSTALL) tools/modsec2lua-resty-waf.pl $(DESTDIR)/bin/
