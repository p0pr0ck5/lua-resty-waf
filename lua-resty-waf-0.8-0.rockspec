package = "lua-resty-waf"
version = "0.8-0"
source = {
   url = "git://github.com/p0pr0ck5/lua-resty-waf",
   tag = "development",
}
description = {
   summary = "High-performance WAF built on the OpenResty stack",
   homepage = "https://github.com/p0pr0ck5/lua-resty-waf",
   license = "GNU GPLv3",
   maintainer = "Robert Paprocki <robert@cryptobells.com>"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "make",
   build_target = false,
   install_target = "install-hard",
}
