OPENRESTY_PREFIX ?= /usr/local/openresty
LUA_LIB_DIR      ?= $(OPENRESTY_PREFIX)/lualib
INSTALL_SOFT     ?= ln -s
INSTALL          ?= install
PWD               = `pwd`

LIBS       = waf waf.lua
C_LIBS     = lua-aho-corasick libinjection
MAKE_LIBS  = $(C_LIBS)
SO_LIBS    = libac.so libinjection.so
RULES      = rules

LOCAL_LIB_DIR = lib/resty

.PHONY: all test install clean test-unit test-acceptance test-regression \
test-translate lua-aho-corasick libinjection clean-libinjection \
clean-lua-aho-corasick

all: $(MAKE_LIBS)

clean: clean-libinjection clean-lua-aho-corasick clean-libs clean-test

clean-install:
	cd $(LUA_LIB_DIR) && rm -rf $(RULES) && rm -f $(SO_LIBS) && cd resty/ && rm -rf $(LIBS)

clean-lua-aho-corasick:
	cd lua-aho-corasick && make clean

clean-lua-ffi-libinjection:
	rm -f $(LOCAL_LIB_DIR)/libinjection.lua

clean-lua-resty-cookie:
	rm -f $(LOCAL_LIB_DIR)/cookie.lua

clean-lua-resty-iputils:
	rm -f $(LOCAL_LIB_DIR)/iputils.lua

clean-libinjection:
	cd libinjection && make clean && git checkout -- .

clean-libs:
	cd lib && rm -f $(SO_LIBS)

clean-test:
	rm -rf t/servroot

lua-aho-corasick:
	cd lua-aho-corasick && make && cp libac.so ../lib/

libinjection:
	cd libinjection && make && cp src/libinjection.so ../lib/

test-unit:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/unit

test-acceptance:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/acceptance

test-regression:
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -r ./t/regression

test-translate:
	prove -r ./t/translate/

test-lua-aho-corasick:
	cd lua-aho-corasick && make test

test: clean all test-unit test-acceptance test-regression test-translate

test-libs: clean all test-lua-aho-corasick test-libinjection

test-recursive: test test-libs

install:
	$(INSTALL) -d $(LUA_LIB_DIR)/resty/waf/storage
	$(INSTALL) -d $(LUA_LIB_DIR)/rules
	$(INSTALL) lib/resty/*.lua $(LUA_LIB_DIR)/resty/
	$(INSTALL) lib/resty/waf/*.lua $(LUA_LIB_DIR)/resty/waf/
	$(INSTALL) lib/resty/waf/storage/*.lua $(LUA_LIB_DIR)/resty/waf/storage/
	$(INSTALL) lib/*.so $(LUA_LIB_DIR)
	$(INSTALL) rules/*.json $(LUA_LIB_DIR)/rules/

install-soft:
	$(INSTALL_SOFT) $(PWD)/lib/resty/* $(LUA_LIB_DIR)/resty/
	$(INSTALL_SOFT) $(PWD)/lib/*.so $(LUA_LIB_DIR)
	$(INSTALL_SOFT) $(PWD)/rules/ $(LUA_LIB_DIR)
