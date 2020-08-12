return {
    {
        id = "913100",
        phase = "access",
        strictness = 1,
        message = "Found User-Agent associated with security scanner",
        anomaly_score = 5,

        data_fn = function()
            return require("resty.waf.data.scanners-user-agents")
        end,

        targets = { [=[headers_t["user-agent"]]=] },

        match = [[waf.operators.pattern_match(target, waf.rule_data["{{ id }}"])]],

        fn =
[[
{{ target_loop }}
]],
    },
    {
        id = "913110",
        phase = "access",
        strictness = 1,
        message = "Found request header associated with security scanner",
        anomaly_score = 5,

        data_fn = function()
            return require("resty.waf.data.scanners-headers")
        end,

        loop = {
            headers = { keys = true, values = true, },
        },

        match = [[waf.operators.pattern_match(target, waf.rule_data["{{ id }}"])]],

        fn =
[[
{{ req_header_loop }}
]],
    },
    {
        -- TODO request body

        id = "913120",
        phase = "access",
        strictness = 1,
        message = "Found request filename/argument associated with security scanner",
        anomaly_score = 5,

        data_fn = function()
            return require("resty.waf.data.scanners-urls")
        end,

        targets = { "uri" },

        match = [[waf.operators.pattern_match(target, waf.rule_data["{{ id }}"])]],

        fn =
[[
{{ target_loop }}
]],
    },
    {
        id = "913101",
        phase = "access",
        strictness = 1,
        message = "Found User-Agent associated with scripting/generic HTTP client",
        anomaly_score = 5,

        data_fn = function()
            return require("resty.waf.data.scripting-user-agents")
        end,

        targets = { [=[headers_t["user-agent"]]=] },

        match = [[waf.operators.pattern_match(target, waf.rule_data["{{ id }}"])]],

        fn =
[[
{{ target_loop }}
]],
    },
    {
        id = "913102",
        phase = "access",
        strictness = 1,
        message = "Found User-Agent associated with web crawler/bot",
        anomaly_score = 5,

        data_fn = function()
            return require("resty.waf.data.crawlers-user-agents")
        end,

        targets = { [=[headers_t["user-agent"]]=] },

        match = [[waf.operators.pattern_match(target, waf.rule_data["{{ id }}"])]],

        fn =
[[
{{ target_loop }}
]],
    },
}