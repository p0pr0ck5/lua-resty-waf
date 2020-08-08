local template = require "resty.waf.template"
local re = require "ngx.re"


local function copy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


local waf = {}


function waf.new(opts)
    return setmetatable({
        rules = {},
        ignored_rules = {},
        ignored_tags = {},

        _ccount = {},
        _compiled = {},
    }, {
        __index = waf,
    })
end


function waf:validate_rule(rule)
    if type(rule) ~= "table" then
        return false
    end

    if type(rule.phase) ~= "string" then
        return false
    end

    if type(rule.id) ~= "string" then
        return false
    end

    if type(rule.fn) ~= "string" then
        return false
    end

    if rule.tags ~= nil and type(rule.tags) ~= "table" then
        return false
    end

    return true
end


function waf:add_rules(rules)
    for _, rule in ipairs(rules) do
        if not self:validate_rule(rule) then
            return false
        end

        local phase = rule.phase
        if not self.rules[phase] then
            self.rules[phase] = {}
        end

        self.rules[phase][#self.rules + 1] = rule
    end

    return true
end


function waf:ignore_rule(id)
    self.ignored_rules[id] = true
end


function waf:ignore_tag(tag)
    self.ignored_tags[tag] = true
end


function waf:should_rule(phase, rule)
    if rule.phase ~= phase then
        return true
    end

    if self.ignored_rules[rule.id] then
        return false
    end

    local tags = rule.tags or {}
    for _, tag in ipairs(tags) do
        if self.ignored_tags[tag] then
            return false
        end
    end

    return true
end


local function render(tpl, context)
    if tpl == nil then
        return tpl
    end

    local eval = function(match)
        if match.op == "if" then
            local c = { "if ", match.expr, " then return [[", match.content, "]] else return [[ "}
            if match.haselse then
                c[#c + 1] = match.elsecontent
            end
            c[#c + 1] = " ]] end"

            local chunk = loadstring(table.concat(c))
            setfenv(chunk, setmetatable(context, {
                __index = _G,
            }))
            return chunk()
        end

        if match.op == "each" then
            local c = {}
            local m = ngx.re.match(match.expr, [[(\w+)\s+in\s+(\w+)]])
            local key = m[1]
            local tbl = m[2]
            local ctx = copy(context)
            for _, elt in ipairs(context[tbl]) do
                ctx[key] = elt
                c[#c + 1] = render(match.content, ctx)
            end
            return table.concat(c)
        end
    end

    -- logic first
    local rendered = ngx.re.gsub(tpl, [[{~\s*(?<op>\w+)(?<expr>.*?)\s*~}(?<content>[\s\S]+?)(?<haselse>{~\s*else\s*~}(?<elsecontent>[\s\S]+))?{~\s*end(?P=op)\s*~}]], eval, "jo")

    -- text rendering
    local mm, _, _ = ngx.re.gsub(rendered, [[{{\s*(?<f>.*)\s+}}]], function(m)
        local t = {}
        local elts = re.split(m.f, [[\s+]])
        local s = elts[1]
        for i = 2, #elts do -- start at 2 to avoid getting the first token
            t[#t + 1] = elts[i]
        end
        return
            type(context[s]) == "function" and context[s](context, table.unpack(t)) or render(context[s], context)
                or
            type(template[s]) == "function" and template[s](context, table.unpack(t)) or render(template[s], context)
                or
            m[0]
    end)
    return mm
end


local function add_rule(t, rule)
    local rule_str = template.rule

    -- render the rule function itself
    rule.fn = render(rule.fn, rule)

    -- render the template
    local c = render(rule_str, rule)

    t[#t + 1] = c
end


function waf:compile(phase)
    local ccount = self._ccount[phase]
    if not ccount then
        ccount = 0
    end
    ccount = ccount + 1
    self._ccount[phase] = ccount

    local t = {
        string.format(template.header, phase, ccount, ngx.now())
    }

    for _, rule in ipairs(self.rules[phase]) do
        if self:should_rule(phase, rule) then
            add_rule(t, rule)
        end
    end

    local raw = table.concat(t)

    local chunk, err = loadstring(raw)
    if err ~= nil then
        return false, err
    end

    self._compiled[phase] = {
        raw = raw,
        chunk = chunk,
    }

    return true, nil
end


function waf:exec(phase)
    local c = self._compiled[phase]
    if not c then
        return
    end

    c.chunk()
end


return waf