OPENRESTY_PREFIX=/usr/local/openresty

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all test

all: ;

test: all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH TEST_NGINX_NO_SHUFFLE=1 prove -r t
