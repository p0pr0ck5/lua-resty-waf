local f = require ("resty.waf")
local waf = f.new({
    config = {
        severity = 4,
    }
})

local ok = waf:add_rules({
    {
        id = "12345",
        phase = "access",
        tags = { "foo" },

        severity = 1,

        match = [[ngx.re.find("foo", "f")]],
        ignore = {
            headers = { "foo" },
            query = {"bar", "baz"},
        },

        --tfn = { "tfn1", "tfn2" },

        fn =
[[
{{ req_loop }}
]],
    },
})
if not ok then error("nope") end

waf.config.active = true

local err
ok, err = waf:compile("access")
if not ok then
    print(err)
end
print(waf._compiled.access.raw)

--waf:exec("access")


--for i = 1, 300000 do
--    waf:exec("access")
--end