local utils = {}


local runner = {}


function utils.new_runner(config)
    return setmetatable({
        anomaly_score = 0,
        log_msgs = {},

        config = config,
    }, {
        __index = runner,
    })
end


function runner:rule_match(id, msg, matched_var, matched_var_name, score)
    ngx.log(ngx.WARN, "HEREEEEEEEE")

    self:log_rule_match(id, msg, matched_var, matched_var_name)

    if self.config.mode == "scoring" then
        self.anomaly_score = self.anomaly_score + score
        return
    end

    if self.config.active == true then
        self:action()
    end
end


function runner:log_rule_match(id, msg, matched_var, matched_var_name)
    ngx.log(ngx.WARN, id, msg, matched_var, matched_var_name)
end


function runner:action()
    ngx.exit(403)
end


return utils