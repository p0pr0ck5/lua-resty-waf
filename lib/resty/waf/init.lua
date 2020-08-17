local operators = require "resty.waf.operators"
local request = require "resty.waf.request"
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


waf.get_headers = request.get_headers
waf.get_uri_args = request.get_uri_args


function waf.new(opts)
    local t = setmetatable({
        rules = {},
        rule_data = {},
        ignored_rules = {},
        ignored_tags = {},

        config = {},

        _ccount = {},
        _compiled = {},
    }, {
        __index = waf,
    })

    for k, v in pairs(opts) do
        t[k] = v
    end

    return t
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

    if type(rule.strictness) ~= "number" then
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

        self.rules[phase][#self.rules[phase] + 1] = rule
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
        return false
    end

    if rule.strictness > self.config.strictness then
        return false
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

    local fn = rule.load_precondition
    if type(fn) == "function" then
        if not fn(self) then
            return false
        end
    end

    return true
end


function waf:render(tpl, context)
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

            local chunk, err = loadstring(table.concat(c))
            if err then print(err) end
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
            for _, elt in ipairs(context[tbl] or {}) do
                ctx[key] = elt
                c[#c + 1] = self:render(match.content, ctx)
            end
            return table.concat(c)
        end
    end

    -- strip comments
    tpl = ngx.re.gsub(tpl, [[{\*.*?\*}\n?]], "")

    -- logic first
    tpl = ngx.re.gsub(tpl, [[{~\s*(?<op>\w+)(?<expr>.*?)\s*~}(?<content>[\s\S]+?)(?<haselse>{~\s*else\s*~}(?<elsecontent>[\s\S]+))?{~\s*end(?P=op)\s*~}]], eval)

    -- text rendering
    local mm, _, _ = ngx.re.gsub(tpl, [[{{\s*(?<f>.*?)\s+}}]], function(m)
        local t = {}
        local elts = re.split(m.f, [[\s+]])
        local s = elts[1]
        for i = 2, #elts do -- start at 2 to avoid getting the first token
            t[#t + 1] = elts[i]
        end
        return
            type(context[s]) == "function" and self:render(context[s](context, table.unpack(t)), context) or self:render(context[s], context)
                or
            type(template[s]) == "function" and self:render(template[s](context, table.unpack(t)), context) or self:render(template[s], context)
                or
            m[0]
    end)
    return mm
end


function waf:add_rule(t, rule)
    local rule_str = template.rule

    -- render the rule function itself
    rule.fn = self:render(rule.fn, rule)

    -- render the template
    local c = self:render(rule_str, rule)

    -- run rule's data fn, if any
    local fn = rule.data_fn
    if type(fn) == "function" then
        self.rule_data[rule.id] = fn()
    end

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
        string.format(template.header, phase, ccount, ngx.now()),
        self:render(template.prologue)
    }

    for _, rule in ipairs(self.rules[phase] or {}) do
        if self:should_rule(phase, rule) then
            self:add_rule(t, rule)
        end
    end

    t[#t + 1] = self:render(template.epilogue, self.config)

    local raw = table.concat(t)

    self._compiled[phase] = {
        raw = raw,
    }

    local chunk, err = loadstring(raw)
    if err ~= nil then
        return false, err
    end

    self._compiled[phase].chunk = chunk

    return true, nil
end


function waf:exec(phase)
    local c = self._compiled[phase]
    if not c then
        return
    end

    local chunk = c.chunk
    setfenv(chunk, setmetatable({
        waf_t = self,
    }, {
        __index = _G,
    }))
    chunk()
end


local runner = {}


function waf:new_runner()
    return (setmetatable({
        anomaly_score = 0,
        log_msgs = {},

        config = self.config,
        rule_data = self.rule_data,

        operators = operators,
    }, {
        __index = runner,
    }))
end


function runner:write_logs()
    for _, msg in ipairs(self.log_msgs) do
        ngx.log(ngx.WARN, msg)
    end
end


function runner:rule_match(id, msg, value, score)
    self:log_rule_match(id, msg, value)

    if self.config.mode == "scoring" then
        self.anomaly_score = self.anomaly_score + score
        return
    end

    if self.config.active == true then
        self:write_logs()
        self:action()
    end
end


function runner:log_rule_match(id, msg, value)
    self.log_msgs[#self.log_msgs+1] = string.format("%s - found %s: %s", id, value, msg)
end


function runner:action()
    ngx.exit(403)
end


return waf