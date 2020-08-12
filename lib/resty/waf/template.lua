return {
  
    header =
[[
-- lua-resty-waf %s/%d (%s)
]],

    prologue =
[[
{* waf_t is provided into the env via setfenv *}
local waf = waf_t:new_runner()

local method = ngx.req.get_method()
local headers_t, headers = waf_t.get_headers()
local query_t, query = waf_t.get_uri_args()
local uri = ngx.var.uri

]],

    epilogue =
[[

waf:write_logs()

{~ if mode == "scoring" ~}
ngx.log(ngx.WARN, "score: ", waf.anomaly_score)
{~ endif ~}

if waf.anomaly_score > {{ anomaly_score_threshold }} then
  waf:action()
end
]],

    rule =
[[
-- BEGIN RULE {{ id }}
do

{{ fn }}

end
-- END RULE {{ id }}

]],

    ignore_fn = function(context, phase)
      return table.concat(context.ignore[phase], " or ")
    end,

    req_loop =
[[
{{ req_header_loop }}
{{ req_query_loop }}
]],

    ignore_tpl = function(context, str)
      return string.format(
[[
{~ if ignore and ignore.%s ~}
  if {{ ignore_fn %s }} then
    goto continue
  end
{~ endif ~}
]], str, str
)
    end,

    transformation_tpl = function(context)
      return
[[
{~ if tfn ~}
{~ each transformation in tfn ~}
  target = {{ transformation }}(target)
{~ endeach ~}
{~ endif ~}
]]
    end,

    target_loop =
[[
local target
{~ each target in targets ~}
target = {{ target }}
if target and {{ match }} then
  {{ rule_match target }}
end
{~ endeach ~}
]],

    loop_fn = function(context, str)
      return string.format(
[[
for i = 1, #%s do
  local target

{~ if loop.%s.keys ~}
  target = %s[i].key
{{ transformation_tpl }}

  if {{ match }} then
    {{ rule_match target }}
  end
{~ endif ~}

{~ if loop.%s.values ~}
  target = %s[i].value
{{ ignore_tpl %s }}
{{ transformation_tpl }}
  if {{ match }} then
    {{ rule_match target }}
  end
{~ endif ~}

{~ if ignore and ignore.%s ~}:: continue ::{~ endif ~}
end]], str, str, str, str, str, str, str, str
      )
    end,

    req_header_loop = [[{{ loop_fn headers }}]],

    req_query_loop = [[{{ loop_fn query }}]],

    rule_match = function(context, value)
      return string.format([[waf:rule_match("{{ id }}", "{{ message }}", ]] .. tostring(value) .. [[, {{ anomaly_score }})]])
    end,
}