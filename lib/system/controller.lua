local _M = {
    _VERSION = '0.01'
}

local ngx_req = ngx.req
local assign_data = {}

local template = require 'resty.template'
local layout = 'layouts/layout.html'

function _M.init(self)
    self.template = template
    if self.withoutLayout then
        self.layout = nil
    else
        self.layout = layout
    end
end

function _M.assign(self, name, value)
    if type(name) == 'table' then
        for i, v in pairs(name) do
            assign_data[i] = v
        end
    else
        assign_data[name] = value
    end
end

function _M.get(name)
    local data = ngx.req.get_uri_args()
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

function _M.post(name)
    local data = ngx_req.get_post_args
    if name then
        if data and data[name] then
            return data[name]
        end
    else
        return data
    end
end

function _M.display(self, tpl, data)
    if data then
        self:assign(data)
    end
    if not tpl then
        tpl = self.controller..'/'..self.action..'.html'
    end
    if self.withoutLayout then
        self.layout = nil
    end
    local view     = template.new(tpl, self.layout)
    if not view then
        func.show_404('initialize the template failed,plesase check the template if exists')
        return
    end
    for k, v in pairs(assign_data) do
        view[k] = v
    end
    view:render()
end

return _M