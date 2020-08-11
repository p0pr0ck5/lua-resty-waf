return {
  
    header =
[[
-- lua-resty-waf %s/%d (%s)
]],

    prologue =
[[
{* waf_t is provided into the env via setfenv *}
local waf = waf_t:new_runner()

local headers, headers_complex = waf_t.get_headers()
local query, query_complex = waf_t.get_uri_args()

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

    loop_fn = function(context, str)
      return string.format(
[[
for i = 1, #%s_complex do
  ngx.log(ngx.WARN, "%s ", i)
  local target

{~ if loop.%s.keys ~}
  target = %s_complex[i].key
  ngx.log(ngx.WARN, "key ", target)

{{ transformation_tpl }}
  ngx.log(ngx.WARN, "key ", target)

  if {{ match }} then
    waf:rule_match()
  end
{~ endif ~}

{~ if loop.%s.values ~}
  target = %s_complex[i].value
  ngx.log(ngx.WARN, "value ", target)

{{ ignore_tpl %s }}
{{ transformation_tpl }}
  ngx.log(ngx.WARN, "value ", target)

  if {{ match }} then
    waf:rule_match()
  end
{~ endif ~}

{~ if ignore and ignore.%s ~}:: continue ::{~ endif ~}
end]], str, str, str, str, str, str, str, str
      )
    end,

    req_header_loop = [[{{ loop_fn headers }}]],

    req_query_loop = [[{{ loop_fn query }}]],
}