local f = require ("resty.waf")
local waf = f.new()

local ok = waf:add_rules({
    {
        id = "12345",
        phase = "access",
        tags = { "foo" },

        match = [[ngx.re.find("foo", "foobar")]],
        --ignore = {
            --headers = { "foo" },
            --query = {"bar", "baz"},
        --},

        --tfn = { "tfn1", "tfn2" },

        fn =
[[
{{ req_header_loop }}
{{ req_query_loop }}
]],
    },
})
if not ok then error("nope") end

local err
ok, err = waf:compile("access")
if not ok then
    print(err)
end
print(waf._compiled.access.raw)


--for i = 1, 10000000 do
--    waf:exec("access")
--end