return {

    header =
[[
-- lua-resty-waf %s/%d (%s)
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
for k, v in pairs(ngx.req.get_headers()) do
  {~ if ignore and ignore.headers ~}if {{ ignore_fn headers }} then goto continue end{~ endif ~}
  {~ if tfn ~}
  {~ each transformation in tfn ~}
  --{{ transformation }}
  {~ endeach ~}
  {~ endif ~}
  if {{ match }} then
    handle()
  end
{~ if ignore and ignore.headers ~}:: continue ::{~ endif ~}
end
]],

    req_query_loop =
[[
for k, v in pairs(ngx.req.get_uri_args()) do
  {~ if ignore and ignore.query ~}if {{ ignore_fn query }} then goto continue end{~ endif ~}
  {~ if tfn ~}
  local s = v
  {~ each transformation in tfn ~}
  s = {{ transformation }}(s)
  {~ endeach ~}
  {~ endif ~}
  if {{ match }} then
    handle()
  end
{~ if ignore and ignore.query ~}:: continue ::{~ endif ~}
end
]],
}