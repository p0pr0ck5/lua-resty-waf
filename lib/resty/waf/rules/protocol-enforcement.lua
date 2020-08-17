return {
    {
        id = "920170",
        phase = "access",
        strictness = 1,
        message = "GET or HEAD Request with Body Content",
        anomaly_score = 5,

        fn =
[[
local m =
    (method == "GET" or method == "HEAD")
        and
    (headers_t["content-length"] and not ngx.re.find(headers_t["content-length"], "^0?$", "oj"))

if m then
    {{ rule_match }}
end
]],
    },
    {
        id = "920171",
        phase = "access",
        strictness = 1,
        message = "GET or HEAD Request with Transfer-Encoding",
        anomaly_score = 5,

        fn =
[[
local m =
    (method == "GET" or method == "HEAD")
        and
    (headers_t["transfer-encoding"])

if m then
    {{ rule_match }}
end
]],
    },
    {
        id = "920181",
        phase = "access",
        strictness = 1,
        message = "Content-Length and Transfer-Encoding headers present",
        anomaly_score = 3,

        fn =
[[
if headers_t["content-length"] and headers_t["transfer-encoding"] then
    {{ rule_match }}
end
]],
    },

    -- TODO 920190

    {
        id = "920210",
        phase = "access",
        strictness = 1,
        message = "Found User-Agent associated with web crawler/bot",
        anomaly_score = 3,

        targets = { [=[headers_t["connection"]]=] },

        match = [[ngx.re.find(target, [=[\b(?:keep-alive|close),\s?(?:keep-alive|close)\b]=], "oj")]],

        fn =
[[
{{ target_loop }}
]]
    },
    {
        id = "920280",
        phase = "access",
        strictness = 1,
        message = "Request Missing a Host Header",
        anomaly_score = 3,

        fn =
[[
if not headers_t["host"] then
    {{ rule_match }}
end
]],
    },
    {
        id = "920290",
        phase = "access",
        strictness = 1,
        message = "Empty Host Header",
        anomaly_score = 3,

        fn =
[[
if headers_t["host"] and headers_t["host"] == "" then
    {{ rule_match }}
end
]],
    },
    {
        id = "920310",
        phase = "access",
        strictness = 1,
        message = "Request Has an Empty Accept Header",
        anomaly_score = 2,

        data_fn = function()
            return { "AppleWebKit", "Android", "Business", "Enterprise", "Entreprise" }
        end,

        fn =
[[
if not headers_t["accept"] and method ~= "OPTIONS" and not waf.operators.pattern_match(headers_t["accept"], waf.rule_data["{{ id }}"]) then
    {{ rule_match }}
end
]],
    },
    {
        id = "920311",
        phase = "access",
        strictness = 1,
        message = "Request Has an Empty Accept Header",
        anomaly_score = 2,

        fn =
[[
if headers_t["accept"] and method ~= "OPTIONS" and not headers_t["user-agent"] then
    {{ rule_match }}
end
]],
    },
    {
        id = "920330",
        phase = "access",
        strictness = 1,
        message = "Empty User Agent Header",
        anomaly_score = 2,

        targets = { [=[headers_t["user-agent"]]=] },

        match = [[target == ""]],

        fn =
[[
{{ target_loop }}
]],
    },
    {
        id = "920340",
        phase = "access",
        strictness = 1,
        message = "Request Containing Content, but Missing Content-Type header",
        anomaly_score = 2,

        fn =
[[
if headers_t["content-length"] and headers_t["content-length"] ~= "0" and not headers_t["content-type"] then
    {{ rule_match }}
end
]],
    },
    {
        id = "920350",
        phase = "access",
        strictness = 1,
        message = "Host header is a numeric IP address",
        anomaly_score = 3,

        targets = { [=[headers_t["host"]]=] },

        match = [=[ngx.re.match(target, [[^[\d.:]+$]], "jo")]=],

        fn =
[[
{{ target_loop }}
]]
    },
    {
        id = "920350",
        phase = "access",
        strictness = 1,
        message = "Too many arguments in request",
        anomaly_score = 5,

        load_precondition = function(waf)
            return waf.config.max_argument_count ~= nil
        end,

        fn =
[[
-- TODO body arg count
if #query > waf.config.max_argument_count then
    {{ rule_match #query }}
end
]],
    },
    {
        id = "920470",
        phase = "access",
        strictness = 1,
        message = "Illegal Content-Type header",
        anomaly_score = 5,

        targets = { [=[headers_t["content-type"]]=] },

        match = [=[ngx.re.match(target, [[^[\w/.+-]+(?:\s?;\s?(?:action|boundary|charset|type|start(?:-info)?)\s?=\s?['\"\w.()+,/:=?<>@-]+)*$]], "jo")]=],

        fn =
[[
{{ target_loop }}
]]
    },
}