return {
  
    header =
[[
-- lua-resty-waf %s/%d (%s)
]],

    prologue =
[[
{* waf_t is provided into the env via setfenv *}
local waf = waf_t:new_runner()

local headers = ngx.req.get_headers()
local query = ngx.req.get_uri_args()

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

    loop_fn = function(context, str)
      return string.format(
[[
  for k, v in pairs(%s) do
    {~ if ignore and ignore.%s ~}if {{ ignore_fn %s }} then goto continue end{~ endif ~}
    {~ if tfn ~}
    local s = v
    {~ each transformation in tfn ~}
    s = {{ transformation }}(s)
    {~ endeach ~}
    {~ endif ~}
    if {{ match }} then
      waf:rule_match()
    end
  {~ if ignore and ignore.%s ~}:: continue ::{~ endif ~}
  end
]], str, str, str, str
      )
    end,

    req_header_loop = [[{{ loop_fn headers }}]],

    req_query_loop = [[{{ loop_fn query }}]],
}