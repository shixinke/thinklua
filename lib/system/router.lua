local _M = {
    _VERSION = '0.01'
}

local mt = {__index = _M }

local ngx_req = ngx.req
local lower = string.lower
local ngx_var = ngx.var
local regex = ngx.re
local str_byte = string.byte
local str_sub = string.sub

local DOT_BYTE = str_byte(':', 1)
local STAR_BYTE = str_byte('*', 1)

function list_rules(rules)
    local tab = {get = {}, post = {}}
    for _, v in pairs(rules) do
        if v.method == 'get' then
            tab.get[#tab.get+1] = v
        elseif v.method == 'post' then
            tab.post[#tab.post+1] = v
        end
    end
    return tab
end

function _M.new()
    local rules = list_rules(config.routes.rules)
    local status = config.routes.router_status
    return setmetatable({
        status = status,
        rules = rules,
        remains = nil
    }, mt)
end

function _M.set_rule(self, rule)
    if type(rule) ~= 'table' then
        return false
    end
    if rule.method then
        self.rules[rule.method][self.rules[rule.method]+1] = rule
    end
end

function _M.route(self)
    if self.status == 'on' then
        local rules = self.rules[lower(ngx_req.get_method())]
        local uri = ngx.var.uri
        if config.routes.url_suffix and config.routes.url_suffix ~= '' then
            uri = regex.sub(uri, config.routes.url_suffix, '')
        end
        if rules then
            for _, v in pairs(rules) do
                if uri == v.pattern then
                    local url_tab, err = func.url_parse(v.url)
                    if url_tab then
                        return url_tab
                    end
                else
                    local path_tab = func.explode('/', uri..'/')
                    local is_regex = regex.find(v.pattern, "\\(", "jo")
                    if is_regex then
                        local m, err = regex.match(uri, v.pattern)
                        if m then
                            m[0] = nil
                            for i, val in pairs(m) do
                                v.url = regex.sub(v.url, '\\$'..i, val)
                            end
                            local url_tab, err = func.url_parse(v.url)
                            if url_tab then
                                return url_tab
                            end
                        end
                    else
                        local rule_tab = func.explode('/', v.pattern..'/')
                        local len = #path_tab
                        local matched = 0
                        local pattern = 0
                        local args = {}
                        for i, v in pairs(rule_tab) do
                            if str_byte(v, 1) == DOT_BYTE then
                                args[str_sub(v, 2)] = path_tab[i]
                                pattern = pattern+1
                            elseif str_byte(v, 1) == STAR_BYTE then
                                pattern = pattern+1
                            elseif v == path_tab[i] then
                                matched = matched + 1
                            else

                            end
                        end
                        if len == (matched + pattern) then
                            local url_tab, err = func.url_parse(v.url)
                            if url_tab then
                                if func.is_empty_table(args) ~= true then
                                    url_tab.params = func.merge(url_tab.params, args)
                                end
                                if matched == 0 then
                                    self.remains = url_tab
                                else
                                    return url_tab
                                end
                            end
                        end
                    end

                end
            end
        end
    end
end





return _M