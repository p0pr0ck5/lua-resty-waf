local f = require ("resty.waf")
local waf = f.new({
    config = {
        strictness = 4,
    }
})

local ok = waf:add_rules({
    {
        id = "12345",
        phase = "access",
        tags = { "foo" },

        strictness = 1,

        anomaly_score = 3,

        match = [[ngx.re.find(target, "FOO", "jo")]],
        ignore = {
            headers = { "foo" },
            query = {"bar", "baz"},
        },

        loop = {
            headers = { keys = true, values = true, },
            query = { keys = true, values = true, },
        },

        tfn = { "string.upper" },

        fn =
[[
{{ req_loop }}
]],
    },

    {
        id = "12346",
        phase = "access",
        strictness = 1,
        anomaly_score = 3,

        fn =
[[
for i = 1, #headers do
    local set = {}

    if set[headers[i].key] then
        waf:rule_match()
    end

    set[headers[i].key] = true
end
]],
    },
})
waf:add_rules(require("resty.waf.rules.method-enforcement"))
ok = waf:add_rules(require("resty.waf.rules.scanner-detection"))
if not ok then error("nope") end

ok = waf:add_rules(require("resty.waf.rules.protocol-enforcement"))
if not ok then error("nope") end

waf.config.active = true
waf.config.anomaly_score_threshold = 5
waf.config.allowed_methods = { "GET", "POST" }
waf.config.max_argument_count = 2

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