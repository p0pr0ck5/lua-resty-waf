return {
  
    header =
[[
-- lua-resty-waf %s/%d (%s)
]],

    prologue =
[[

local utils = require "resty.waf.utils"
local waf = utils.new_runner(waf_t.config)

local headers = ngx.req.get_headers()
local args = ngx.req.get_uri_args()

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

    req_header_loop =
[[
for k, v in pairs(headers) do
  {~ if ignore and ignore.headers ~}if {{ ignore_fn headers }} then goto continue end{~ endif ~}
  {~ if tfn ~}
  local s = v
  {~ each transformation in tfn ~}
  s = {{ transformation }}(s)
  {~ endeach ~}
  {~ endif ~}
  if {{ match }} then
    waf:rule_match()
  end
{~ if ignore and ignore.headers ~}:: continue ::{~ endif ~}
end
]],

    req_query_loop =
[[
for k, v in pairs(args) do
  {~ if ignore and ignore.query ~}if {{ ignore_fn query }} then goto continue end{~ endif ~}
  {~ if tfn ~}
  local s = v
  {~ each transformation in tfn ~}
  s = {{ transformation }}(s)
  {~ endeach ~}
  {~ endif ~}
  if {{ match }} then
    waf:rule_match()
  end
{~ if ignore and ignore.query ~}:: continue ::{~ endif ~}
end
]],
}