return {
    {
        id = "911100",
        phase = "access",
        strictness = 1,
        message = "Method is not allowed by policy",
        anomaly_score = 5,

        tags = {
            "application-multi",
            "language-multi",
            "platform-multi",
            "attack-generic",
            "paranoia-level/1",
            "OWASP_CRS",
            "capec/1000/210/272/220/274",
            "PCI/12.1",
            "OWASP_CRS/3.3.0",
        },

        fn =
[[
local ok = false
for i = 1, #waf.config.allowed_methods do
    if method == waf.config.allowed_methods[i] then
        ok = true
        break
    end
end

if not ok then
    {{ rule_match method }}
end
]],
    },
}